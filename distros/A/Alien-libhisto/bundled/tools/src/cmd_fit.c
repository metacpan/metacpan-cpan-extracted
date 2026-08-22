/*
 * CLI subcommand histo fit: parametric curve fitting and ASCII plot overlay.
 */

#include "cli_common.h"
#include "histo/fit.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <math.h>
#include <unistd.h>

static void print_fit_usage(FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "Usage: histo-fit [OPTIONS] [HISTOGRAM_FILE...]\n");
    fprintf(out, "       histo fit [OPTIONS] [HISTOGRAM_FILE...]\n\n");
    fprintf(out, "Fits parametric models to 1D histograms using non-linear least squares / Poisson MLE.\n\n");
    fprintf(out, "Model & Optimization Options:\n");
    fprintf(out, "  -m, --model=<TYPE>       Model: gaussian (default), exponential, polynomial, breit-wigner,\n");
    fprintf(out, "                           power-law, lognormal, gauss+linear, weibull, gamma, poisson, laplace\n");
    fprintf(out, "  -d, --degree=<N>         Degree for polynomial model (default: 1, range: 0..10)\n");
    fprintf(out, "      --mle                Use Poisson Maximum Likelihood Estimation (-2 ln L) instead of Chi-Square\n");
    fprintf(out, "      --unweighted         Use Unweighted Least Squares\n");
    fprintf(out, "  -b, --bounds=<IDX=MIN:MAX> Set parameter lower and upper bounds (e.g. --bounds=2=0.1:10.0)\n");
    fprintf(out, "  -f, --fix-param=<IDX=VAL>  Freeze parameter to constant value (e.g. --fix-param=1=0.0)\n");
    fprintf(out, "      --range=<MIN:MAX>    Sub-range window for fitting [MIN, MAX]\n");
    fprintf(out, "      --confidence=<LEV>   Confidence interval level (default: 0.95)\n\n");
    fprintf(out, "Output & Display Options:\n");
    fprintf(out, "  -j, --json               Emit structured JSON fit results\n");
    fprintf(out, "  -q, --quiet              Output only optimal parameter values (tab-separated)\n");
    fprintf(out, "  -p, --plot               Render optional ASCII curve overlay above parameter table\n");
    fprintf(out, "  -i, --input=<FILE>       Input histogram or raw sample stream file (default: stdin)\n");
    fprintf(out, "  -h, --help               Show this help message\n");
}

static const char *get_param_name(histo_fit_model_t model, size_t idx, uint32_t poly_degree, char *buf, size_t buf_size) {
    switch (model) {
        case HISTO_FIT_MODEL_GAUSSIAN:
            if (idx == 0) return "Amplitude (A)";
            if (idx == 1) return "Mean (\xce\xbc)";
            if (idx == 2) return "Std Dev (\xcf\x83)";
            break;
        case HISTO_FIT_MODEL_EXPONENTIAL:
            if (idx == 0) return "Amplitude (A)";
            if (idx == 1) return "Decay Rate (\xce\xbb)";
            if (idx == 2) return "Baseline (C)";
            break;
        case HISTO_FIT_MODEL_POLYNOMIAL:
            (void)poly_degree;
            if (idx == 0) snprintf(buf, buf_size, "c0 (constant)");
            else if (idx == 1) snprintf(buf, buf_size, "c1 (linear x)");
            else snprintf(buf, buf_size, "c%zu (x^%zu)", idx, idx);
            return buf;
        case HISTO_FIT_MODEL_BREIT_WIGNER:
            if (idx == 0) return "Scale (A)";
            if (idx == 1) return "Peak Position (M)";
            if (idx == 2) return "FWHM (\xce\x93)";
            break;
        case HISTO_FIT_MODEL_POWER_LAW:
            if (idx == 0) return "Amplitude (A)";
            if (idx == 1) return "Exponent (k)";
            if (idx == 2) return "Origin Shift (x0)";
            break;
        case HISTO_FIT_MODEL_LOG_NORMAL:
            if (idx == 0) return "Scale (A)";
            if (idx == 1) return "Log-Mean (\xce\xbc)";
            if (idx == 2) return "Log-Std (\xcf\x83)";
            break;
        case HISTO_FIT_MODEL_GAUSSIAN_PLUS_LINEAR:
            if (idx == 0) return "Amplitude (A)";
            if (idx == 1) return "Mean (\xce\xbc)";
            if (idx == 2) return "Std Dev (\xcf\x83)";
            if (idx == 3) return "Intercept (c0)";
            if (idx == 4) return "Slope (c1)";
            break;
        case HISTO_FIT_MODEL_WEIBULL:
            if (idx == 0) return "Scale (A)";
            if (idx == 1) return "Shape (k)";
            if (idx == 2) return "Scale (\xce\xbb)";
            break;
        case HISTO_FIT_MODEL_GAMMA:
            if (idx == 0) return "Scale (A)";
            if (idx == 1) return "Shape (k)";
            if (idx == 2) return "Scale (\xce\xb8)";
            break;
        case HISTO_FIT_MODEL_POISSON:
            if (idx == 0) return "Scale (A)";
            if (idx == 1) return "Rate (\xce\xbb)";
            break;
        case HISTO_FIT_MODEL_LAPLACE:
            if (idx == 0) return "Scale (A)";
            if (idx == 1) return "Location (\xce\xbc)";
            if (idx == 2) return "Diversity (b)";
            break;
        default:
            break;
    }
    snprintf(buf, buf_size, "p%zu", idx);
    return buf;
}

static const char *get_model_title_and_formula(histo_fit_model_t model, uint32_t poly_degree, char *buf, size_t buf_size) {
    switch (model) {
        case HISTO_FIT_MODEL_GAUSSIAN:
            return "Gaussian Peak [ f(x) = A \xc2\xb7 exp(-(x - \xce\xbc)\xc2\xb2 / (2\xcf\x83\xc2\xb2)) ]";
        case HISTO_FIT_MODEL_EXPONENTIAL:
            return "Exponential Decay [ f(x) = A \xc2\xb7 exp(-\xce\xbb\xc2\xb7x) + C ]";
        case HISTO_FIT_MODEL_POLYNOMIAL:
            snprintf(buf, buf_size, "Polynomial (Degree %u) [ f(x) = \xe2\x88\x91 c_k\xc2\xb7x^k ]", poly_degree);
            return buf;
        case HISTO_FIT_MODEL_BREIT_WIGNER:
            return "Breit-Wigner / Cauchy-Lorentz [ f(x) = (A/\xcf\x80) \xc2\xb7 (\xce\x93/2) / ((x-M)\xc2\xb2 + (\xce\x93/2)\xc2\xb2) ]";
        case HISTO_FIT_MODEL_POWER_LAW:
            return "Power Law [ f(x) = A \xc2\xb7 (x - x0)^k ]";
        case HISTO_FIT_MODEL_LOG_NORMAL:
            return "Log-Normal [ f(x) = (A / (x\xc2\xb7\xcf\x83\xe2\x88\x9a(2\xcf\x80))) \xc2\xb7 exp(-(ln(x)-\xce\xbc)\xc2\xb2 / (2\xcf\x83\xc2\xb2)) ]";
        case HISTO_FIT_MODEL_GAUSSIAN_PLUS_LINEAR:
            return "Gaussian Peak + Linear Background [ f(x) = A \xc2\xb7 exp(-(x - \xce\xbc)\xc2\xb2 / (2\xcf\x83\xc2\xb2)) + c0 + c1\xc2\xb7x ]";
        case HISTO_FIT_MODEL_WEIBULL:
            return "Weibull [ f(x) = A \xc2\xb7 (k/\xce\xbb) \xc2\xb7 (x/\xce\xbb)^(k-1) \xc2\xb7 exp(-(x/\xce\xbb)^k) ]";
        case HISTO_FIT_MODEL_GAMMA:
            return "Gamma / Erlang [ f(x) = A \xc2\xb7 (x^(k-1) \xc2\xb7 exp(-x/\xce\xb8)) / (\xce\x93(k)\xc2\xb7\xce\xb8^k) ]";
        case HISTO_FIT_MODEL_POISSON:
            return "Poisson [ f(x) = A \xc2\xb7 (\xce\xbb^x \xc2\xb7 exp(-\xce\xbb)) / \xce\x93(x+1) ]";
        case HISTO_FIT_MODEL_LAPLACE:
            return "Laplace [ f(x) = (A / (2b)) \xc2\xb7 exp(-|x - \xce\xbc| / b) ]";
        default:
            return "Custom Model";
    }
}

static double eval_model_point(histo_fit_model_t model, uint32_t poly_degree, const double *p, double x) {
    size_t num_params = histo_fit_model_num_params(model, poly_degree);
    return histo_fit_eval(model, p, num_params, x);
}

static void print_fit_plot(const histo_t *h, histo_fit_model_t model, uint32_t poly_degree, const histo_fit_result_t *res, FILE *out) {
    if (!h || !res || !res->params || !out) return;
    int width = cli_get_terminal_width(80);
    if (width > 80) width = 80;
    int height = 12;

    uint32_t nbins = histo_nbins(h);
    double h_min = 0.0, h_max = 0.0;
    histo_range(h, &h_min, &h_max);

    double max_val = 0.0;
    for (uint32_t i = 0; i < nbins; ++i) {
        double c = 0.0;
        histo_bin_content(h, i, &c);
        if (c > max_val) max_val = c;
        double low = 0.0, high = 0.0;
        histo_bin_bounds(h, i, &low, &high);
        double f_val = eval_model_point(model, poly_degree, res->params, 0.5 * (low + high));
        if (f_val > max_val) max_val = f_val;
    }
    if (max_val <= 0.0) max_val = 1.0;

    int plot_w = width - 12;
    if (plot_w < 20) plot_w = 20;

    fprintf(out, "\n  Data Overlay Plot [ █ Data Bins, * Fitted Curve ]:\n");
    for (int row = height; row >= 0; --row) {
        double y_level = ((double)row / (double)height) * max_val;
        fprintf(out, "  %7.1f ┤ ", y_level);

        for (int col = 0; col < plot_w; ++col) {
            double x_norm = (double)col / (double)(plot_w - 1);
            double x_curr = h_min + x_norm * (h_max - h_min);
            int64_t bidx = 0;
            histo_find_bin(h, x_curr, &bidx);
            double bin_c = 0.0;
            if (bidx >= 0 && (uint32_t)bidx < nbins) {
                histo_bin_content(h, (uint32_t)bidx, &bin_c);
            }
            double fit_c = eval_model_point(model, poly_degree, res->params, x_curr);

            double row_low = ((double)row - 0.5) / (double)height * max_val;
            double row_high = ((double)row + 0.5) / (double)height * max_val;
            bool is_fit = (fit_c >= row_low && fit_c <= row_high);
            bool is_bin = (bin_c >= y_level);

            if (is_fit && is_bin) {
                fputc('*', out);
            } else if (is_fit) {
                fputc('*', out);
            } else if (is_bin) {
                fputs("█", out);
            } else {
                fputc(' ', out);
            }
        }
        fputc('\n', out);
    }
    fprintf(out, "          ┼");
    for (int col = 0; col < plot_w; ++col) fputs("─", out);
    fputc('\n', out);

    fprintf(out, "          %-*.*g %*.*g\n\n", plot_w / 2, 6, h_min, plot_w - (plot_w / 2), 6, h_max);
}

static void print_fit_results_table(const histo_t *h, histo_fit_model_t model, uint32_t poly_degree,
                                   const histo_fit_result_t *res, double confidence, bool do_plot, FILE *out) {
    if (!res || !out) return;
    char title_buf[128];
    const char *title = get_model_title_and_formula(model, poly_degree, title_buf, sizeof(title_buf));

    if (do_plot) {
        print_fit_plot(h, model, poly_degree, res, out);
    }

    fprintf(out, "================================================================================\n");
    fprintf(out, " MODEL: %s\n", title);
    fprintf(out, "================================================================================\n");
    fprintf(out, "  Param  Name                   Estimate      Std. Error       %.0f%% Conf. Interval\n", confidence * 100.0);

    /* Normal z-score multiplier for confidence interval */
    double z = 1.95996;
    if (fabs(confidence - 0.6827) < 0.02) z = 1.0;
    else if (fabs(confidence - 0.90) < 0.02) z = 1.64485;
    else if (fabs(confidence - 0.95) < 0.02) z = 1.95996;
    else if (fabs(confidence - 0.99) < 0.02) z = 2.57583;

    char p_buf[64];
    for (size_t i = 0; i < res->num_params; ++i) {
        const char *pname = get_param_name(model, i, poly_degree, p_buf, sizeof(p_buf));
        double est = res->params[i];
        double err = res->param_errors ? res->param_errors[i] : 0.0;
        double ci_low = est - z * err;
        double ci_high = est + z * err;

        fprintf(out, "  [%zu]    %-20s %12.4f     \xc2\xb1 %9.4f        [ %10.4f, %10.4f ]\n",
               i, pname, est, err, ci_low, ci_high);
    }

    fprintf(out, "--------------------------------------------------------------------------------\n");
    fprintf(out, " GOODNESS OF FIT:\n");
    if (res->ndf > 0) {
        fprintf(out, "  \xcf\x87\xc2\xb2 / NDF       = %.2f / %d (%.3f)\n", res->chi2, res->ndf, res->reduced_chi2);
    } else {
        fprintf(out, "  \xcf\x87\xc2\xb2           = %.2f (NDF <= 0)\n", res->chi2);
    }
    fprintf(out, "  p-value        = %.4g%s\n", res->p_value, res->p_value > 0.05 ? " (Consistent with model)" : " (Significant deviation)");
    fprintf(out, "  Log-Likelihood = %.2f  |  AIC = %.2f  |  BIC = %.2f\n", res->log_likelihood, res->aic, res->bic);
    fprintf(out, "  Convergence    = %s (%u iterations, %s)\n",
           res->converged ? "Converged" : "FAILED to converge",
           res->iterations, res->stop_reason ? res->stop_reason : "N/A");
    fprintf(out, "================================================================================\n");
}

static void print_fit_results_json(histo_fit_model_t model, uint32_t poly_degree, const histo_fit_result_t *res, FILE *out) {
    if (!res || !out) return;
    char p_buf[64];
    fprintf(out, "{\n");
    fprintf(out, "  \"model\": \"%s\",\n",
           model == HISTO_FIT_MODEL_GAUSSIAN ? "gaussian" :
           model == HISTO_FIT_MODEL_EXPONENTIAL ? "exponential" :
           model == HISTO_FIT_MODEL_POLYNOMIAL ? "polynomial" :
           model == HISTO_FIT_MODEL_BREIT_WIGNER ? "breit-wigner" : "power-law");
    if (model == HISTO_FIT_MODEL_POLYNOMIAL) {
        fprintf(out, "  \"poly_degree\": %u,\n", poly_degree);
    }
    fprintf(out, "  \"converged\": %s,\n", res->converged ? "true" : "false");
    fprintf(out, "  \"status\": %d,\n", (int)res->status);
    fprintf(out, "  \"stop_reason\": \"%s\",\n", res->stop_reason ? res->stop_reason : "");
    fprintf(out, "  \"iterations\": %u,\n", res->iterations);
    fprintf(out, "  \"chi2\": %.8g,\n", res->chi2);
    fprintf(out, "  \"ndf\": %d,\n", res->ndf);
    fprintf(out, "  \"reduced_chi2\": %.8g,\n", res->reduced_chi2);
    fprintf(out, "  \"p_value\": %.8g,\n", res->p_value);
    fprintf(out, "  \"log_likelihood\": %.8g,\n", res->log_likelihood);
    fprintf(out, "  \"aic\": %.8g,\n", res->aic);
    fprintf(out, "  \"bic\": %.8g,\n", res->bic);

    fprintf(out, "  \"parameters\": [\n");
    for (size_t i = 0; i < res->num_params; ++i) {
        const char *pname = get_param_name(model, i, poly_degree, p_buf, sizeof(p_buf));
        fprintf(out, "    {\n");
        fprintf(out, "      \"index\": %zu,\n", i);
        fprintf(out, "      \"name\": \"%s\",\n", pname);
        fprintf(out, "      \"estimate\": %.8g,\n", res->params[i]);
        fprintf(out, "      \"error\": %.8g\n", res->param_errors ? res->param_errors[i] : 0.0);
        fprintf(out, "    }%s\n", (i + 1 < res->num_params) ? "," : "");
    }
    fprintf(out, "  ],\n");

    fprintf(out, "  \"covariance_matrix\": [\n");
    for (size_t i = 0; i < res->num_params; ++i) {
        fprintf(out, "    [");
        for (size_t j = 0; j < res->num_params; ++j) {
            double c = res->cov_matrix ? res->cov_matrix[i * res->num_params + j] : 0.0;
            fprintf(out, "%.8g%s", c, (j + 1 < res->num_params) ? ", " : "");
        }
        fprintf(out, "]%s\n", (i + 1 < res->num_params) ? "," : "");
    }
    fprintf(out, "  ]\n");
    fprintf(out, "}\n");
}

int histo_cli_fit(int argc, char **argv, FILE *out, FILE *err) {
    if (!out) out = stdout;
    if (!err) err = stderr;
    optind = 1;

    histo_fit_model_t model = HISTO_FIT_MODEL_GAUSSIAN;
    uint32_t poly_degree = 1;
    histo_fit_loss_t loss_type = HISTO_FIT_LOSS_CHI2;
    double range_min = 0.0, range_max = 0.0;
    double confidence = 0.95;
    bool do_json = false;
    bool do_quiet = false;
    bool do_plot = false;
    const char *input_file = NULL;

    double lower_bounds_arr[16];
    double upper_bounds_arr[16];
    bool fixed_params_arr[16];
    bool has_lower = false, has_upper = false, has_fixed = false;

    for (int i = 0; i < 16; ++i) {
        lower_bounds_arr[i] = -INFINITY;
        upper_bounds_arr[i] = INFINITY;
        fixed_params_arr[i] = false;
    }

    for (int i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            print_fit_usage(out);
            return 0;
        } else if (strcmp(arg, "-j") == 0 || strcmp(arg, "--json") == 0) {
            do_json = true;
        } else if (strcmp(arg, "-q") == 0 || strcmp(arg, "--quiet") == 0) {
            do_quiet = true;
        } else if (strcmp(arg, "-p") == 0 || strcmp(arg, "--plot") == 0) {
            do_plot = true;
        } else if (strcmp(arg, "--mle") == 0) {
            loss_type = HISTO_FIT_LOSS_POISSON_MLE;
        } else if (strcmp(arg, "--unweighted") == 0) {
            loss_type = HISTO_FIT_LOSS_UNWEIGHTED_LS;
        } else if (strncmp(arg, "-m=", 3) == 0 || strncmp(arg, "--model=", 8) == 0 || strcmp(arg, "-m") == 0 || strcmp(arg, "--model") == 0) {
            const char *val = NULL;
            if (arg[1] == 'm' && arg[2] == '=') val = arg + 3;
            else if (strncmp(arg, "--model=", 8) == 0) val = arg + 8;
            else if (i + 1 < argc) val = argv[++i];

            if (val) {
                if (strcmp(val, "gaussian") == 0 || strcmp(val, "gauss") == 0) model = HISTO_FIT_MODEL_GAUSSIAN;
                else if (strcmp(val, "exponential") == 0 || strcmp(val, "exp") == 0) model = HISTO_FIT_MODEL_EXPONENTIAL;
                else if (strcmp(val, "polynomial") == 0 || strcmp(val, "poly") == 0) model = HISTO_FIT_MODEL_POLYNOMIAL;
                else if (strcmp(val, "breit-wigner") == 0 || strcmp(val, "bw") == 0 || strcmp(val, "cauchy") == 0) model = HISTO_FIT_MODEL_BREIT_WIGNER;
                else if (strcmp(val, "power-law") == 0 || strcmp(val, "power") == 0) model = HISTO_FIT_MODEL_POWER_LAW;
                else if (strcmp(val, "lognormal") == 0 || strcmp(val, "log-normal") == 0 || strcmp(val, "log_normal") == 0) model = HISTO_FIT_MODEL_LOG_NORMAL;
                else if (strcmp(val, "gauss+linear") == 0 || strcmp(val, "gauss_linear") == 0 || strcmp(val, "gauss+poly1") == 0) model = HISTO_FIT_MODEL_GAUSSIAN_PLUS_LINEAR;
                else if (strcmp(val, "weibull") == 0) model = HISTO_FIT_MODEL_WEIBULL;
                else if (strcmp(val, "gamma") == 0 || strcmp(val, "erlang") == 0) model = HISTO_FIT_MODEL_GAMMA;
                else if (strcmp(val, "poisson") == 0) model = HISTO_FIT_MODEL_POISSON;
                else if (strcmp(val, "laplace") == 0 || strcmp(val, "double-exponential") == 0) model = HISTO_FIT_MODEL_LAPLACE;
                else {
                    fprintf(err, "Error: Unknown model '%s'\n", val);
                    return 1;
                }
            }
        } else if (strncmp(arg, "-d=", 3) == 0 || strncmp(arg, "--degree=", 9) == 0 || strcmp(arg, "-d") == 0 || strcmp(arg, "--degree") == 0) {
            const char *val = (arg[1] == 'd' && arg[2] == '=') ? arg + 3 :
                              (strncmp(arg, "--degree=", 9) == 0) ? arg + 9 :
                              (i + 1 < argc) ? argv[++i] : NULL;
            if (val) poly_degree = (uint32_t)atoi(val);
        } else if (strncmp(arg, "-c=", 3) == 0 || strncmp(arg, "--confidence=", 13) == 0 || strcmp(arg, "-c") == 0 || strcmp(arg, "--confidence") == 0) {
            const char *val = (arg[1] == 'c' && arg[2] == '=') ? arg + 3 :
                              (strncmp(arg, "--confidence=", 13) == 0) ? arg + 13 :
                              (i + 1 < argc) ? argv[++i] : NULL;
            if (val) confidence = atof(val);
        } else if (strncmp(arg, "-b=", 3) == 0 || strncmp(arg, "--bounds=", 9) == 0 || strcmp(arg, "-b") == 0 || strcmp(arg, "--bounds") == 0) {
            const char *val = (arg[1] == 'b' && arg[2] == '=') ? arg + 3 :
                              (strncmp(arg, "--bounds=", 9) == 0) ? arg + 9 :
                              (i + 1 < argc) ? argv[++i] : NULL;
            if (val) {
                int pidx = 0;
                double bmin = 0.0, bmax = 0.0;
                if (sscanf(val, "%d=%lf:%lf", &pidx, &bmin, &bmax) == 3 && pidx >= 0 && pidx < 16) {
                    lower_bounds_arr[pidx] = bmin;
                    upper_bounds_arr[pidx] = bmax;
                    has_lower = true;
                    has_upper = true;
                }
            }
        } else if (strncmp(arg, "-f=", 3) == 0 || strncmp(arg, "--fix-param=", 12) == 0 || strcmp(arg, "-f") == 0 || strcmp(arg, "--fix-param") == 0) {
            const char *val = (arg[1] == 'f' && arg[2] == '=') ? arg + 3 :
                              (strncmp(arg, "--fix-param=", 12) == 0) ? arg + 12 :
                              (i + 1 < argc) ? argv[++i] : NULL;
            if (val) {
                int pidx = 0;
                double fval = 0.0;
                if (sscanf(val, "%d=%lf", &pidx, &fval) == 2 && pidx >= 0 && pidx < 16) {
                    lower_bounds_arr[pidx] = fval;
                    upper_bounds_arr[pidx] = fval;
                    fixed_params_arr[pidx] = true;
                    has_fixed = true;
                }
            }
        } else if (strncmp(arg, "--range=", 8) == 0) {
            sscanf(arg + 8, "%lf:%lf", &range_min, &range_max);
        } else if (strncmp(arg, "-i=", 3) == 0 || strncmp(arg, "--input=", 8) == 0 || strcmp(arg, "-i") == 0 || strcmp(arg, "--input") == 0) {
            input_file = (arg[1] == 'i' && arg[2] == '=') ? arg + 3 :
                         (strncmp(arg, "--input=", 8) == 0) ? arg + 8 :
                         (i + 1 < argc) ? argv[++i] : NULL;
        } else if (arg[0] == '-' && arg[1] != '\0') {
            fprintf(err, "Unknown option '%s'. Run 'histo-fit --help' for usage.\n", arg);
            return 1;
        } else {
            if (!input_file) input_file = arg;
        }
    }

    histo_t *h = NULL;
    FILE *fp = stdin;
    if (input_file && strcmp(input_file, "-") != 0) {
        fp = fopen(input_file, "rb");
        if (!fp) {
            fprintf(err, "Error: Cannot open input file '%s'\n", input_file);
            return 1;
        }
    }

    cli_input_format_t fmt = cli_detect_stream_format(fp);
    if (fmt == CLI_INPUT_BINARY_HISTO || fmt == CLI_INPUT_JSON_HISTO) {
        if (cli_read_histogram_from_stream(fp, &h) != HISTO_OK) {
            fprintf(err, "Error: Failed to deserialize input histogram\n");
            if (fp != stdin) fclose(fp);
            return 1;
        }
    } else {
        size_t cap = 1024, count = 0;
        double *buf = (double *)malloc(cap * sizeof(double));
        if (!buf) {
            if (fp != stdin) fclose(fp);
            return 1;
        }
        double v = 0.0;
        while (fscanf(fp, "%lf", &v) == 1) {
            if (count >= cap) {
                cap *= 2;
                double *nb = (double *)realloc(buf, cap * sizeof(double));
                if (!nb) { free(buf); if (fp != stdin) fclose(fp); return 1; }
                buf = nb;
            }
            buf[count++] = v;
        }
        if (count < 5) {
            fprintf(err, "Error: Insufficient samples in stream to fit (got %zu, need >= 5)\n", count);
            free(buf);
            if (fp != stdin) fclose(fp);
            return 1;
        }
        double s_min = buf[0], s_max = buf[0];
        for (size_t k = 1; k < count; ++k) {
            if (buf[k] < s_min) s_min = buf[k];
            if (buf[k] > s_max) s_max = buf[k];
        }
        if (s_min >= s_max) {
            s_min -= 1.0;
            s_max += 1.0;
        }
        double pad = (s_max - s_min) * 0.05;
        h = histo_create_uniform(50, s_min - pad, s_max + pad, HISTO_FLAG_TRACK_SUMW2);
        if (!h) { free(buf); if (fp != stdin) fclose(fp); return 1; }
        for (size_t k = 0; k < count; ++k) {
            histo_fill(h, buf[k]);
        }
        free(buf);
    }
    if (fp != stdin) fclose(fp);

    /* Configure fitting options */
    histo_fit_options_t opts;
    histo_fit_options_init(&opts);
    opts.loss_type = loss_type;
    opts.poly_degree = poly_degree;
    opts.range_min = range_min;
    opts.range_max = range_max;
    if (has_lower) opts.lower_bounds = lower_bounds_arr;
    if (has_upper) opts.upper_bounds = upper_bounds_arr;
    if (has_fixed) opts.fixed_params = fixed_params_arr;

    histo_fit_result_t *res = NULL;
    histo_status_t fit_st = histo_fit_model(h, model, NULL, &opts, &res);
    if (fit_st < 0 || !res) {
        fprintf(err, "Error: Curve fitting failed with status code %d (%s)\n",
                (int)fit_st, res && res->stop_reason ? res->stop_reason : "unspecified error");
        if (res) histo_fit_result_destroy(res);
        histo_destroy(h);
        return 1;
    }

    if (do_json) {
        print_fit_results_json(model, poly_degree, res, out);
    } else if (do_quiet) {
        for (size_t i = 0; i < res->num_params; ++i) {
            fprintf(out, "%.8g%s", res->params[i], (i + 1 < res->num_params) ? "\t" : "\n");
        }
    } else {
        print_fit_results_table(h, model, poly_degree, res, confidence, do_plot, out);
    }

    histo_fit_result_destroy(res);
    histo_destroy(h);
    return 0;
}
