/*
 * Declarative, table-driven command-line argument parser for libhisto CLI.
 * Strict ISO C99, zero external dependencies, thread-safe, and portable across GCC/Clang/MSVC.
 */

#include "cli_opt.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if !defined(_WIN32)
#include <strings.h>
#endif
#include <errno.h>
#include <ctype.h>

void cli_opt_init(cli_opt_parser_t *parser,
                  const cli_opt_spec_t *specs,
                  size_t num_specs,
                  const char *prog_name,
                  const char *usage_args,
                  const char *summary) {
    if (!parser) return;
    memset(parser, 0, sizeof(*parser));
    parser->specs = specs;
    parser->num_specs = num_specs;
    parser->prog_name = prog_name ? prog_name : "histo";
    parser->usage_args = usage_args ? usage_args : "[OPTIONS] [ARGUMENTS...]";
    parser->summary = summary;
    parser->positionals = NULL;
    parser->num_positionals = 0;
    parser->positionals_cap = 0;
    parser->has_error = false;
    parser->help_requested = false;
    parser->err_msg[0] = '\0';
}

void cli_opt_free(cli_opt_parser_t *parser) {
    if (!parser) return;
    if (parser->positionals) {
        free(parser->positionals);
        parser->positionals = NULL;
    }
    parser->num_positionals = 0;
    parser->positionals_cap = 0;
}

const char *cli_opt_error(const cli_opt_parser_t *parser) {
    if (!parser) return "";
    return parser->err_msg;
}

static bool parse_int_val(const char *str, int *out) {
    if (!str || !*str) return false;
    char *endptr = NULL;
    errno = 0;
    long val = strtol(str, &endptr, 10);
    if (errno != 0 || *endptr != '\0') return false;
    *out = (int)val;
    return true;
}

static bool parse_uint32_val(const char *str, uint32_t *out) {
    if (!str || !*str) return false;
    while (*str && isspace((unsigned char)*str)) str++;
    if (*str == '-') return false; /* Unsigned cannot be negative */
    char *endptr = NULL;
    errno = 0;
    unsigned long val = strtoul(str, &endptr, 10);
    if (errno != 0 || *endptr != '\0') return false;
#if ULONG_MAX > 0xFFFFFFFFUL
    if (val > 0xFFFFFFFFUL) return false;
#endif
    *out = (uint32_t)val;
    return true;
}

static bool parse_int64_val(const char *str, int64_t *out) {
    if (!str || !*str) return false;
    char *endptr = NULL;
    errno = 0;
    long long val = strtoll(str, &endptr, 10);
    if (errno != 0 || *endptr != '\0') return false;
    *out = (int64_t)val;
    return true;
}

static bool parse_uint64_val(const char *str, uint64_t *out) {
    if (!str || !*str) return false;
    while (*str && isspace((unsigned char)*str)) str++;
    if (*str == '-') return false;
    char *endptr = NULL;
    errno = 0;
    unsigned long long val = strtoull(str, &endptr, 10);
    if (errno != 0 || *endptr != '\0') return false;
    *out = (uint64_t)val;
    return true;
}

static bool parse_double_val(const char *str, double *out) {
    if (!str || !*str) return false;
    char *endptr = NULL;
    errno = 0;
    double val = strtod(str, &endptr);
    if (errno != 0 || *endptr != '\0') return false;
    *out = val;
    return true;
}

static int assign_spec_value(cli_opt_parser_t *parser,
                             const cli_opt_spec_t *spec,
                             const char *opt_label,
                             const char *val) {
    switch (spec->type) {
        case CLI_OPT_TYPE_BOOL: {
            if (spec->target) {
                bool bval = !(spec->flags & CLI_OPT_FLAG_SET_FALSE);
                *(bool *)spec->target = bval;
            }
            return 0;
        }
        case CLI_OPT_TYPE_STRING: {
            if (spec->target) {
                *(const char **)spec->target = val;
            }
            return 0;
        }
        case CLI_OPT_TYPE_INT: {
            int iv = 0;
            if (!val || !parse_int_val(val, &iv)) {
                snprintf(parser->err_msg, sizeof(parser->err_msg),
                         "Invalid integer value '%s' for option '%s'.", val ? val : "", opt_label);
                parser->has_error = true;
                return 1;
            }
            if (spec->target) *(int *)spec->target = iv;
            return 0;
        }
        case CLI_OPT_TYPE_UINT32: {
            uint32_t uv = 0;
            if (!val || !parse_uint32_val(val, &uv)) {
                snprintf(parser->err_msg, sizeof(parser->err_msg),
                         "Invalid unsigned integer value '%s' for option '%s'.", val ? val : "", opt_label);
                parser->has_error = true;
                return 1;
            }
            if (spec->target) *(uint32_t *)spec->target = uv;
            return 0;
        }
        case CLI_OPT_TYPE_INT64: {
            int64_t i64 = 0;
            if (!val || !parse_int64_val(val, &i64)) {
                snprintf(parser->err_msg, sizeof(parser->err_msg),
                         "Invalid integer value '%s' for option '%s'.", val ? val : "", opt_label);
                parser->has_error = true;
                return 1;
            }
            if (spec->target) *(int64_t *)spec->target = i64;
            return 0;
        }
        case CLI_OPT_TYPE_UINT64: {
            uint64_t u64 = 0;
            if (!val || !parse_uint64_val(val, &u64)) {
                snprintf(parser->err_msg, sizeof(parser->err_msg),
                         "Invalid unsigned integer value '%s' for option '%s'.", val ? val : "", opt_label);
                parser->has_error = true;
                return 1;
            }
            if (spec->target) *(uint64_t *)spec->target = u64;
            return 0;
        }
        case CLI_OPT_TYPE_DOUBLE: {
            double dv = 0.0;
            if (!val || !parse_double_val(val, &dv)) {
                snprintf(parser->err_msg, sizeof(parser->err_msg),
                         "Invalid numeric value '%s' for option '%s'.", val ? val : "", opt_label);
                parser->has_error = true;
                return 1;
            }
            if (spec->target) *(double *)spec->target = dv;
            return 0;
        }
        case CLI_OPT_TYPE_CHAR: {
            char cv = (val && *val) ? val[0] : '\0';
            if (spec->target) *(char *)spec->target = cv;
            return 0;
        }
        case CLI_OPT_TYPE_CALLBACK: {
            if (spec->callback) {
                int res = spec->callback(opt_label, val, spec->target,
                                         parser->err_msg, sizeof(parser->err_msg));
                if (res != 0) {
                    parser->has_error = true;
                    if (parser->err_msg[0] == '\0') {
                        snprintf(parser->err_msg, sizeof(parser->err_msg),
                                 "Invalid value '%s' for option '%s'.", val ? val : "", opt_label);
                    }
                    return 1;
                }
            }
            return 0;
        }
        default:
            return 0;
    }
}

int cli_opt_parse(cli_opt_parser_t *parser, int argc, char **argv, int start_idx) {
    if (!parser || argc < 0 || !argv) return 1;
    if (start_idx < 0) start_idx = 0;

    parser->has_error = false;
    parser->help_requested = false;
    parser->err_msg[0] = '\0';

    if (parser->positionals) {
        free(parser->positionals);
        parser->positionals = NULL;
    }
    parser->num_positionals = 0;
    parser->positionals_cap = (argc >= start_idx) ? (argc - start_idx + 1) : 1;
    parser->positionals = (const char **)malloc(sizeof(const char *) * (size_t)parser->positionals_cap);
    if (!parser->positionals) {
        snprintf(parser->err_msg, sizeof(parser->err_msg), "Memory allocation failure in CLI option parser.");
        parser->has_error = true;
        return 1;
    }

    bool *was_set = NULL;
    if (parser->num_specs > 0) {
        was_set = (bool *)calloc(parser->num_specs, sizeof(bool));
        if (!was_set) {
            snprintf(parser->err_msg, sizeof(parser->err_msg), "Memory allocation failure in CLI option parser.");
            parser->has_error = true;
            return 1;
        }
    }

    for (int i = start_idx; i < argc; ++i) {
        const char *arg = argv[i];
        if (!arg) continue;

        /* Positional terminator "--" */
        if (strcmp(arg, "--") == 0) {
            for (int j = i + 1; j < argc; ++j) {
                parser->positionals[parser->num_positionals++] = argv[j];
            }
            break;
        }

        /* Check help flag */
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            parser->help_requested = true;
            free(was_set);
            return -1;
        }

        /* Long Option: --foo */
        if (arg[0] == '-' && arg[1] == '-' && arg[2] != '\0') {
            const char *opt_str = arg + 2;
            const char *eq = strchr(opt_str, '=');
            size_t name_len = eq ? (size_t)(eq - opt_str) : strlen(opt_str);

            const cli_opt_spec_t *matched_spec = NULL;
            size_t matched_idx = 0;
            bool is_negated_bool = false;

            for (size_t s = 0; s < parser->num_specs; ++s) {
                const cli_opt_spec_t *spec = &parser->specs[s];
                if (spec->long_name &&
                    strncmp(spec->long_name, opt_str, name_len) == 0 &&
                    spec->long_name[name_len] == '\0') {
                    matched_spec = spec;
                    matched_idx = s;
                    break;
                }
                if (spec->alias &&
                    strncmp(spec->alias, opt_str, name_len) == 0 &&
                    spec->alias[name_len] == '\0') {
                    matched_spec = spec;
                    matched_idx = s;
                    break;
                }
            }

            /* If not found directly, check for automatic --no-<long_name> boolean negation */
            if (!matched_spec && strncmp(opt_str, "no-", 3) == 0 && name_len > 3) {
                const char *pos_name = opt_str + 3;
                size_t pos_len = name_len - 3;
                for (size_t s = 0; s < parser->num_specs; ++s) {
                    const cli_opt_spec_t *spec = &parser->specs[s];
                    if (spec->type == CLI_OPT_TYPE_BOOL && spec->long_name &&
                        strncmp(spec->long_name, pos_name, pos_len) == 0 &&
                        spec->long_name[pos_len] == '\0') {
                        matched_spec = spec;
                        matched_idx = s;
                        is_negated_bool = true;
                        break;
                    }
                }
            }

            if (!matched_spec) {
                snprintf(parser->err_msg, sizeof(parser->err_msg),
                         "Unknown option '%s'. Run '%s --help' for usage.", arg, parser->prog_name);
                parser->has_error = true;
                free(was_set);
                return 1;
            }

            was_set[matched_idx] = true;

            if (matched_spec->type == CLI_OPT_TYPE_BOOL) {
                if (eq) {
                    snprintf(parser->err_msg, sizeof(parser->err_msg),
                             "Option '--%.*s' does not take a value.", (int)name_len, opt_str);
                    parser->has_error = true;
                    free(was_set);
                    return 1;
                }
                if (matched_spec->target) {
                    bool val = !(matched_spec->flags & CLI_OPT_FLAG_SET_FALSE);
                    if (is_negated_bool) val = !val;
                    *(bool *)matched_spec->target = val;
                }
            } else {
                const char *val = NULL;
                if (eq) {
                    val = eq + 1;
                } else if (matched_spec->flags & CLI_OPT_FLAG_OPTIONAL_ARG) {
                    if (i + 1 < argc && (argv[i + 1][0] != '-' ||
                        (argv[i + 1][1] >= '0' && argv[i + 1][1] <= '9'))) {
                        val = argv[++i];
                    } else {
                        val = matched_spec->def_val_desc ? matched_spec->def_val_desc : "";
                    }
                } else {
                    if (i + 1 < argc) {
                        val = argv[++i];
                    } else {
                        snprintf(parser->err_msg, sizeof(parser->err_msg),
                                 "Option '--%.*s' requires an argument.", (int)name_len, opt_str);
                        parser->has_error = true;
                        free(was_set);
                        return 1;
                    }
                }

                char opt_label[128];
                snprintf(opt_label, sizeof(opt_label), "--%.*s", (int)name_len, opt_str);
                if (assign_spec_value(parser, matched_spec, opt_label, val) != 0) {
                    free(was_set);
                    return 1;
                }
            }
        }
        /* Short Option(s): -f, -abc, -n50, -n=50, -n 50 */
        else if (arg[0] == '-' && arg[1] != '\0' && strcmp(arg, "-") != 0) {
            const char *p = arg + 1;

            while (*p) {
                char c = *p;

                /* Check for help */
                if (c == 'h') {
                    parser->help_requested = true;
                    free(was_set);
                    return -1;
                }

                const cli_opt_spec_t *matched_spec = NULL;
                size_t matched_idx = 0;

                for (size_t s = 0; s < parser->num_specs; ++s) {
                    const cli_opt_spec_t *spec = &parser->specs[s];
                    if (spec->short_name && spec->short_name == c) {
                        matched_spec = spec;
                        matched_idx = s;
                        break;
                    }
                }

                if (!matched_spec) {
                    snprintf(parser->err_msg, sizeof(parser->err_msg),
                             "Unknown option '-%c'. Run '%s --help' for usage.", c, parser->prog_name);
                    parser->has_error = true;
                    free(was_set);
                    return 1;
                }

                was_set[matched_idx] = true;

                if (matched_spec->type == CLI_OPT_TYPE_BOOL) {
                    if (matched_spec->target) {
                        bool val = !(matched_spec->flags & CLI_OPT_FLAG_SET_FALSE);
                        *(bool *)matched_spec->target = val;
                    }
                    p++; /* Advance to next bundled flag */
                } else {
                    /* Non-boolean takes argument */
                    const char *val = NULL;
                    if (*(p + 1) == '=') {
                        val = p + 2;
                    } else if (*(p + 1) != '\0') {
                        val = p + 1;
                    } else if (matched_spec->flags & CLI_OPT_FLAG_OPTIONAL_ARG) {
                        if (i + 1 < argc && (argv[i + 1][0] != '-' ||
                            (argv[i + 1][1] >= '0' && argv[i + 1][1] <= '9'))) {
                            val = argv[++i];
                        } else {
                            val = matched_spec->def_val_desc ? matched_spec->def_val_desc : "";
                        }
                    } else {
                        if (i + 1 < argc) {
                            val = argv[++i];
                        } else {
                            snprintf(parser->err_msg, sizeof(parser->err_msg),
                                     "Option '-%c' requires an argument.", c);
                            parser->has_error = true;
                            free(was_set);
                            return 1;
                        }
                    }

                    char opt_label[16];
                    snprintf(opt_label, sizeof(opt_label), "-%c", c);
                    if (assign_spec_value(parser, matched_spec, opt_label, val) != 0) {
                        free(was_set);
                        return 1;
                    }
                    break; /* Remainder of token consumed as argument value */
                }
            }
        }
        /* Positional argument (including single dash "-") */
        else {
            parser->positionals[parser->num_positionals++] = arg;
        }
    }

    /* Verify all required options were specified */
    if (was_set) {
        for (size_t s = 0; s < parser->num_specs; ++s) {
            const cli_opt_spec_t *spec = &parser->specs[s];
            if ((spec->flags & CLI_OPT_FLAG_REQUIRED) && !was_set[s]) {
                if (spec->long_name) {
                    snprintf(parser->err_msg, sizeof(parser->err_msg),
                             "Option '--%s' is required.", spec->long_name);
                } else {
                    snprintf(parser->err_msg, sizeof(parser->err_msg),
                             "Option '-%c' is required.", spec->short_name);
                }
                parser->has_error = true;
                free(was_set);
                return 1;
            }
        }
        free(was_set);
    }

    return 0;
}

void cli_opt_print_help(const cli_opt_parser_t *parser, FILE *out) {
    if (!parser) return;
    if (!out) out = stdout;

    fprintf(out, "Usage: %s %s\n", parser->prog_name, parser->usage_args);
    if (parser->summary && *parser->summary) {
        fprintf(out, "\n%s\n", parser->summary);
    }
    fprintf(out, "\nOptions:\n");

    for (size_t s = 0; s < parser->num_specs; ++s) {
        const cli_opt_spec_t *spec = &parser->specs[s];
        if (spec->flags & CLI_OPT_FLAG_HIDDEN) continue;

        char opt_buf[64] = {0};

        if (spec->short_name && spec->long_name) {
            if (spec->type == CLI_OPT_TYPE_BOOL) {
                snprintf(opt_buf, sizeof(opt_buf), "  -%c, --%s",
                         spec->short_name, spec->long_name);
            } else if (spec->flags & CLI_OPT_FLAG_OPTIONAL_ARG) {
                snprintf(opt_buf, sizeof(opt_buf), "  -%c, --%s[=%s]",
                         spec->short_name, spec->long_name,
                         spec->val_name ? spec->val_name : "VAL");
            } else {
                snprintf(opt_buf, sizeof(opt_buf), "  -%c, --%s=<%s>",
                         spec->short_name, spec->long_name,
                         spec->val_name ? spec->val_name : "VAL");
            }
        } else if (spec->long_name) {
            if (spec->type == CLI_OPT_TYPE_BOOL) {
                snprintf(opt_buf, sizeof(opt_buf), "      --%s", spec->long_name);
            } else if (spec->flags & CLI_OPT_FLAG_OPTIONAL_ARG) {
                snprintf(opt_buf, sizeof(opt_buf), "      --%s[=%s]",
                         spec->long_name, spec->val_name ? spec->val_name : "VAL");
            } else {
                snprintf(opt_buf, sizeof(opt_buf), "      --%s=<%s>",
                         spec->long_name, spec->val_name ? spec->val_name : "VAL");
            }
        } else if (spec->short_name) {
            if (spec->type == CLI_OPT_TYPE_BOOL) {
                snprintf(opt_buf, sizeof(opt_buf), "  -%c", spec->short_name);
            } else {
                snprintf(opt_buf, sizeof(opt_buf), "  -%c <%s>",
                         spec->short_name, spec->val_name ? spec->val_name : "VAL");
            }
        }

        fprintf(out, "%-28s", opt_buf);

        if (spec->description) {
            fprintf(out, " %s", spec->description);
        }
        if (spec->def_val_desc && *spec->def_val_desc) {
            fprintf(out, " (default: %s)", spec->def_val_desc);
        }
        if (spec->alias && *spec->alias) {
            fprintf(out, " (alias: --%s)", spec->alias);
        }
        fprintf(out, "\n");
    }

    fprintf(out, "  -h, --help                   Show this help message\n");
}
