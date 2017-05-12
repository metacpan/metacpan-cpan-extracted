#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
 * Macros and symbolic constants
 */

#define RAND_WEIGHT ( ((float)rand() / (float)RAND_MAX) - 0.5 )

#define sqr(x) ((x) * (x))

typedef struct {
    double **input_to_hidden;
    double **hidden_to_output;
} SYNAPSE;

SYNAPSE weight;

typedef struct {
    double *hidden;
    double *output;
} ERROR;

ERROR error;

typedef struct {
    double *input;
    double *hidden;
    double *output;
    double *target;
} LAYER;

LAYER neuron;

typedef struct {
    int input;
    int hidden;
    int output;
} NEURON_COUNT;

typedef struct {
    float        learn_rate;
    double       delta;
    int          use_bipolar;
    SYNAPSE      weight;
    ERROR        error;
    LAYER        neuron;
    NEURON_COUNT size;
    double       *tmp;
} NEURAL_NETWORK;

int networks = 0;
NEURAL_NETWORK **network = NULL;

AV*    get_array_from_aoa(SV* scalar, int index);
AV*    get_array(SV* aref);
SV*    get_element(AV* array, int index);

double sigmoid(NEURAL_NETWORK *n, double val);
double sigmoid_derivative(NEURAL_NETWORK *n, double val);
float  get_float_element(AV* array, int index);
int    is_array_ref(SV* ref);
void   c_assign_random_weights(NEURAL_NETWORK *);
void   c_back_propagate(NEURAL_NETWORK *);
void   c_destroy_network(int);
void   c_feed(NEURAL_NETWORK *, double *input, double *output, int learn);
void   c_feed_forward(NEURAL_NETWORK *);
float  c_get_learn_rate(int);
void   c_set_learn_rate(int, float);
SV*    c_export_network(int handle);
int    c_import_network(SV *);

#define ABS(x)        ((x) > 0.0 ? (x) : -(x))

int is_array_ref(SV* ref)
{
    if (SvROK(ref) && SvTYPE(SvRV(ref)) == SVt_PVAV)
        return 1;
    else
        return 0;
}

double sigmoid(NEURAL_NETWORK *n, double val)
{
    return 1.0 / (1.0 + exp(-n->delta * val));
}

double sigmoid_derivative(NEURAL_NETWORK *n, double val)
{
    /*
     * It's always called with val=sigmoid(x) and we want sigmoid'(x).
     *
     * Since sigmoid'(x) = delta * sigmoid(x) * (1 - sigmoid(x))
     * the value we return is extremely simple.
     *
     * sigmoid_derivative(x) is NOT sigmoid'(x).
     */

    return n->delta * val * (1.0 - val);
}

/* Not using tanh() as this is already defined in math headers */
double hyperbolic_tan(NEURAL_NETWORK *n, double val)
{
    double epx = exp(n->delta * val);
    double emx = exp(-n->delta * val);

    return (epx - emx) / (epx + emx);
}

double hyperbolic_tan_derivative(NEURAL_NETWORK *n, double val)
{
    /*
     * It's always called with val=tanh(delta*x) and we want tanh'(delta*x).
     *
     * Since tanh'(delta*x) = delta * (1 - tanh(delta*x)^2)
     * the value we return is extremely simple.
     *
     * hyperbolic_tan_derivative(x) is NOT tanh'(x).
     */

    return n->delta * (1.0 - val * val);
}

AV* get_array(SV* aref)
{
    if (! is_array_ref(aref))
        croak("get_array() argument is not an array reference");
    
    return (AV*) SvRV(aref);
}

float get_float_element(AV* array, int index)
{
    SV **sva;
    SV *sv;

    sva = av_fetch(array, index, 0);
    if (!sva)
        return 0.0;

    sv = *sva;
    return SvNV(sv);
}

SV* get_element(AV* array, int index)
{
    SV   **temp;
    temp = av_fetch(array, index, 0);

    if (!temp)
        croak("Item %d in array is not defined", index);

    return *temp;
}

AV* get_array_from_aoa(SV* aref, int index)
{
    SV *elem;
    AV *array;

    /* dereference array and get requested arrayref */
    array  = get_array(aref);
    elem   = get_element(array, index);
    
    /* dereference array ref */
    return get_array(elem);
}

NEURAL_NETWORK *c_get_network(int handle)
{
    NEURAL_NETWORK *n;

    if (handle < 0 || handle >= networks)
        croak("Invalid neural network handle");

    n = network[handle];

    if (n == NULL)
        croak("Stale neural network handle");

    return n;
}

int c_new_handle(void)
{
    int handle = -1;

    /*
     * Allocate the network array if not already done.
     * Then allocate a new handle for the network.
     */

    if (network == NULL) {
        int i;

        networks = 10;
        network = malloc(networks * sizeof(*network));

        for (i = 0; i < networks; i++)
            network[i] = NULL;

        handle = 0;
    } else {
        int i;

        for (i = 0; i < networks; i++) {
            if (network[i] == NULL) {
                handle = i;
                break;
            }
        }

        if (handle == -1) {
            handle = networks;
            networks += 10;
            network = realloc(network, networks * sizeof(*network));

            for (i = networks - 10; i < networks; i++)
                network[i] = NULL;
        }
    }

    network[handle] = malloc(sizeof(NEURAL_NETWORK));

    return handle;
}

float c_get_learn_rate(int handle)
{
    NEURAL_NETWORK *n = c_get_network(handle);

    return n->learn_rate;
}

void c_set_learn_rate(int handle, float rate)
{
    NEURAL_NETWORK *n = c_get_network(handle);

    n->learn_rate = rate;
}

double c_get_delta(int handle)
{
    NEURAL_NETWORK *n = c_get_network(handle);

    return n->delta;
}


void c_set_delta(int handle, double delta)
{
    NEURAL_NETWORK *n = c_get_network(handle);

    n->delta = delta;
}

int c_get_use_bipolar(int handle)
{
    NEURAL_NETWORK *n = c_get_network(handle);

    return n->use_bipolar;
}

void c_set_use_bipolar(int handle, int bipolar)
{
    NEURAL_NETWORK *n = c_get_network(handle);

    n->use_bipolar = bipolar;
}

int c_create_network(NEURAL_NETWORK *n)
{
    int i;
    /* each of the next two variables has an extra row for the "bias" */
    int input_layer_with_bias  = n->size.input  + 1;
    int hidden_layer_with_bias = n->size.hidden + 1;

    n->learn_rate = .2;
    n->delta = 1.0;
    n->use_bipolar = 0;

    n->tmp = malloc(sizeof(double) * n->size.input);

    n->neuron.input  = malloc(sizeof(double) * n->size.input);
    n->neuron.hidden = malloc(sizeof(double) * n->size.hidden);
    n->neuron.output = malloc(sizeof(double) * n->size.output);
    n->neuron.target = malloc(sizeof(double) * n->size.output);

    n->error.hidden  = malloc(sizeof(double) * n->size.hidden);
    n->error.output  = malloc(sizeof(double) * n->size.output);
    
    /* one extra for sentinel */
    n->weight.input_to_hidden  
        = malloc(sizeof(void *) * (input_layer_with_bias + 1));
    n->weight.hidden_to_output 
        = malloc(sizeof(void *) * (hidden_layer_with_bias + 1));

    if(!n->weight.input_to_hidden || !n->weight.hidden_to_output) {
        printf("Initial malloc() failed\n");
        return 0;
    }
    
    /* now allocate the actual rows */
    for(i = 0; i < input_layer_with_bias; i++) {
        n->weight.input_to_hidden[i] 
            = malloc(hidden_layer_with_bias * sizeof(double));
        if(n->weight.input_to_hidden[i] == 0) {
            free(*n->weight.input_to_hidden);
            printf("Second malloc() to weight.input_to_hidden failed\n");
            return 0;
        }
    }

    /* now allocate the actual rows */
    for(i = 0; i < hidden_layer_with_bias; i++) {
        n->weight.hidden_to_output[i] 
            = malloc(n->size.output * sizeof(double));
        if(n->weight.hidden_to_output[i] == 0) {
            free(*n->weight.hidden_to_output);
            printf("Second malloc() to weight.hidden_to_output failed\n");
            return 0;
        }
    }

    /* initialize the sentinel value */
    n->weight.input_to_hidden[input_layer_with_bias]   = 0;
    n->weight.hidden_to_output[hidden_layer_with_bias] = 0;

    return 1;
}

void c_destroy_network(int handle)
{
    double **row;
    NEURAL_NETWORK *n = c_get_network(handle);

    for(row = n->weight.input_to_hidden; *row != 0; row++) {
        free(*row);
    }
    free(n->weight.input_to_hidden);

    for(row = n->weight.hidden_to_output; *row != 0; row++) {
        free(*row);
    }
    free(n->weight.hidden_to_output);

    free(n->neuron.input);
    free(n->neuron.hidden);
    free(n->neuron.output);
    free(n->neuron.target);

    free(n->error.hidden);
    free(n->error.output);

    free(n->tmp);

    network[handle] = NULL;
}

/*
 * Build a Perl reference on array `av'.
 * This performs something like "$rv = \@av;" in Perl.
 */
SV *build_rv(AV *av)
{
    SV *rv;

    /*
     * To understand what is going on here, look at retrieve_ref()
     * in the Storable.xs file.  In particular, we don't perform
     * an SvREFCNT_inc(av) because the av we're supplying is going
     * to be referenced only by the REF we're building here.
     *        --RAM
     */

    rv = NEWSV(10002, 0);
    sv_upgrade(rv, SVt_RV);
    SvRV(rv) = (SV *) av;
    SvROK_on(rv);

    return rv;
}

/*
 * Build reference to a 2-dimensional array, implemented as an array
 * or array references.  The holding array has `rows' rows and each array
 * reference has `columns' entries.
 *
 * The name "axa" denotes the "product" of 2 arrays.
 */
SV *build_axaref(void *arena, int rows, int columns)
{
    AV *av;
    int i;
    double **p;

    av = newAV();
    av_extend(av, rows);

    for (i = 0, p = arena; i < rows; i++, p++) {
        int j;
        double *q;
        AV *av2;

        av2 = newAV();
        av_extend(av2, columns);

        for (j = 0, q = *p; j < columns; j++, q++)
            av_store(av2, j, newSVnv((NV) *q));

        av_store(av, i, build_rv(av2));
    }

    return build_rv(av);
}

#define EXPORT_VERSION    1
#define EXPORTED_ITEMS    9

/*
 * Exports the C data structures to the Perl world for serialization
 * by Storable.  We don't want to duplicate the logic of Storable here
 * even though we have to do some low-level Perl object construction.
 *
 * The structure we return is an array reference, which contains the
 * following items:
 *
 *  0    the export version number, in case format changes later
 *  1    the amount of neurons in the input layer
 *  2    the amount of neurons in the hidden layer
 *  3    the amount of neurons in the output layer
 *  4    the learning rate
 *  5    the sigmoid delta
 *  6    whether to use a bipolar (tanh) routine instead of the sigmoid
 *  7    [[weight.input_to_hidden[0]], [weight.input_to_hidden[1]], ...]
 *  8    [[weight.hidden_to_output[0]], [weight.hidden_to_output[1]], ...]
 */
SV *c_export_network(int handle)
{
    NEURAL_NETWORK *n = c_get_network(handle);
    AV *av;
    int i = 0;

    av = newAV();
    av_extend(av, EXPORTED_ITEMS);

    av_store(av, i++,  newSViv(EXPORT_VERSION));
    av_store(av, i++,  newSViv(n->size.input));
    av_store(av, i++,  newSViv(n->size.hidden));
    av_store(av, i++,  newSViv(n->size.output));
    av_store(av, i++,  newSVnv(n->learn_rate));
    av_store(av, i++,  newSVnv(n->delta));
    av_store(av, i++,  newSViv(n->use_bipolar));
    av_store(av, i++,
                build_axaref(n->weight.input_to_hidden,
                    n->size.input + 1, n->size.hidden + 1));
    av_store(av, i++,
                build_axaref(n->weight.hidden_to_output,
                    n->size.hidden + 1, n->size.output));

    if (i != EXPORTED_ITEMS)
        croak("BUG in c_export_network()");

    return build_rv(av);
}

/*
 * Load a Perl array of array (a matrix) with "rows" rows and "columns" columns
 * into the pre-allocated C array of arrays.
 *
 * The "hold" argument is an holding array and the Perl array of array which
 * we expect is at index "idx" within that holding array.
 */
void c_load_axa(AV *hold, int idx, void *arena, int rows, int columns)
{
    SV **sav;
    SV *rv;
    AV *av;
    int i;
    double **array = arena;

    sav = av_fetch(hold, idx, 0);
    if (sav == NULL)
        croak("serialized item %d is not defined", idx);

    rv = *sav;
    if (!is_array_ref(rv))
        croak("serialized item %d is not an array reference", idx);

    av = get_array(rv);        /* This is an array of array refs */

    for (i = 0; i < rows; i++) {
        double *row = array[i];
        int j;
        AV *subav;

        sav = av_fetch(av, i, 0);
        if (sav == NULL)
            croak("serialized item %d has undefined row %d", idx, i);
        rv = *sav;
        if (!is_array_ref(rv))
            croak("row %d of serialized item %d is not an array ref", i, idx);

        subav = get_array(rv);

        for (j = 0; j < columns; j++)
            row[j] = get_float_element(subav, j);
    }
}

/*
 * Create new network from a retrieved data structure, such as the one
 * produced by c_export_network().
 */
int c_import_network(SV *rv)
{
    NEURAL_NETWORK *n;
    int handle;
    SV **sav;
    AV *av;
    int i = 0;

    /*
     * Unfortunately, since those data come from the outside, we need
     * to validate most of the structural information to make sure
     * we're not fed garbage or something we cannot process, like a
     * newer version of the serialized data. This makes the code heavy.
     *        --RAM
     */

    if (!is_array_ref(rv))
        croak("c_import_network() not given an array reference");

    av = get_array(rv);

    /* Check version number */
    sav = av_fetch(av, i++, 0);
    if (sav == NULL || SvIVx(*sav) != EXPORT_VERSION)
        croak("c_import_network() given unknown version %d",
            sav == NULL ? 0 : SvIVx(*sav));

    /* Check length -- at version 1, length is fixed to 13 */
    if (av_len(av) + 1 != EXPORTED_ITEMS)
        croak("c_import_network() not given a %d-item array reference",
            EXPORTED_ITEMS);

    handle = c_new_handle();
    n = c_get_network(handle);

    sav = av_fetch(av, i++, 0);
    if (sav == NULL)
        croak("undefined input size (item %d)", i - 1);
    n->size.input  = SvIVx(*sav);

    sav = av_fetch(av, i++, 0);
    if (sav == NULL)
        croak("undefined hidden size (item %d), i - 1");
    n->size.hidden = SvIVx(*sav);

    sav = av_fetch(av, i++, 0);
    if (sav == NULL)
        croak("undefined output size (item %d)", i - 1);
    n->size.output = SvIVx(*sav);

    if (!c_create_network(n))
        return -1;

    sav = av_fetch(av, i++, 0);
    if (sav == NULL)
        croak("undefined learn_rate (item %d)", i - 1);
    n->learn_rate = SvNVx(*sav);

    sav = av_fetch(av, i++, 0);
    if (sav == NULL)
        croak("undefined delta (item %d)", i - 1);
    n->delta = SvNVx(*sav);

    sav = av_fetch(av, i++, 0);
    if (sav == NULL)
        croak("undefined use_bipolar (item %d)", i - 1);
    n->use_bipolar = SvIVx(*sav);

    c_load_axa(av, i++, n->weight.input_to_hidden,
        n->size.input + 1, n->size.hidden + 1);
    c_load_axa(av, i++, n->weight.hidden_to_output,
        n->size.hidden + 1, n->size.output);

    return handle;
}

/*
 * Support functions for back propogation
 */

void c_assign_random_weights(NEURAL_NETWORK *n)
{
    int hid, inp, out;

    for (inp = 0; inp < n->size.input + 1; inp++) {
        for (hid = 0; hid < n->size.hidden; hid++) {
            n->weight.input_to_hidden[inp][hid] = RAND_WEIGHT;
        }
    }

    for (hid = 0; hid < n->size.hidden + 1; hid++) {
        for (out = 0; out < n->size.output; out++) {
            n->weight.hidden_to_output[hid][out] = RAND_WEIGHT;
        }
    }
}

/*
 * Feed-forward Algorithm
 */

void c_feed_forward(NEURAL_NETWORK *n)
{
    int inp, hid, out;
    double sum;
    double (*activation)(NEURAL_NETWORK *, double);

    activation = n->use_bipolar ? hyperbolic_tan : sigmoid;

    /* calculate input to hidden layer */
    for (hid = 0; hid < n->size.hidden; hid++) {

        sum = 0.0;
        for (inp = 0; inp < n->size.input; inp++) {
            sum += n->neuron.input[inp]
                * n->weight.input_to_hidden[inp][hid];
        }

        /* add in bias */
        sum += n->weight.input_to_hidden[n->size.input][hid];

        n->neuron.hidden[hid] = (*activation)(n, sum);
    }

    /* calculate the hidden to output layer */
    for (out = 0; out < n->size.output; out++) {

        sum = 0.0;
        for (hid = 0; hid < n->size.hidden; hid++) {
            sum += n->neuron.hidden[hid] 
                * n->weight.hidden_to_output[hid][out];
        }

        /* add in bias */
        sum += n->weight.hidden_to_output[n->size.hidden][out];

        n->neuron.output[out] = (*activation)(n, sum);
    }
}

/*
 * Back-propogation algorithm.  This is where the learning gets done.
 */
void c_back_propagate(NEURAL_NETWORK *n)
{
    int inp, hid, out;
    double (*activation_derivative)(NEURAL_NETWORK *, double);

    activation_derivative = n->use_bipolar ?
        hyperbolic_tan_derivative : sigmoid_derivative;

    /* calculate the output layer error (step 3 for output cell) */
    for (out = 0; out < n->size.output; out++) {
        n->error.output[out] =
            (n->neuron.target[out] - n->neuron.output[out]) 
              * (*activation_derivative)(n, n->neuron.output[out]);
    }

    /* calculate the hidden layer error (step 3 for hidden cell) */
    for (hid = 0; hid < n->size.hidden; hid++) {

        n->error.hidden[hid] = 0.0;
        for (out = 0; out < n->size.output; out++) {
            n->error.hidden[hid] 
                += n->error.output[out] 
                 * n->weight.hidden_to_output[hid][out];
        }
        n->error.hidden[hid] 
            *= (*activation_derivative)(n, n->neuron.hidden[hid]);
    }

    /* update the weights for the output layer (step 4) */
    for (out = 0; out < n->size.output; out++) {
        for (hid = 0; hid < n->size.hidden; hid++) {
            n->weight.hidden_to_output[hid][out] 
                += (n->learn_rate 
                  * n->error.output[out] 
                  * n->neuron.hidden[hid]);
        }

        /* update the bias */
        n->weight.hidden_to_output[n->size.hidden][out] 
            += (n->learn_rate 
              * n->error.output[out]);
    }

    /* update the weights for the hidden layer (step 4) */
    for (hid = 0; hid < n->size.hidden; hid++) {

        for  (inp = 0; inp < n->size.input; inp++) {
            n->weight.input_to_hidden[inp][hid] 
                += (n->learn_rate 
                  * n->error.hidden[hid] 
                  * n->neuron.input[inp]);
        }

        /* update the bias */
        n->weight.input_to_hidden[n->size.input][hid] 
            += (n->learn_rate 
              * n->error.hidden[hid]);
    }
}

/*
 * Compute the Mean Square Error between the actual output and the
 * targeted output.
 */
double mean_square_error(NEURAL_NETWORK *n, double *target)
{
    double error = 0.0;
    int i;

    for (i = 0; i < n->size.output; i++)
        error += sqr(target[i] - n->neuron.output[i]);

    return 0.5 * error;
}

double c_train(int handle, SV* input, SV* output)
{
    NEURAL_NETWORK *n = c_get_network(handle);
    int i,length;
    AV *array;
    double *input_array  = malloc(sizeof(double) * n->size.input);
    double *output_array = malloc(sizeof(double) * n->size.output);
    double error;

    if (! is_array_ref(input) || ! is_array_ref(output)) {
        croak("train() takes two arrayrefs.");
    }
    
    array  = get_array(input);
    length = av_len(array)+ 1;
    
    if (length != n->size.input) {
        croak("Length of input array does not match network");
    }
    for (i = 0; i < length; i++) {
        input_array[i] = get_float_element(array, i);
    }

    array  = get_array(output);
    length = av_len(array) + 1;
    
    if (length != n->size.output) {
        croak("Length of output array does not match network");
    }
    for (i = 0; i < length; i++) {
        output_array[i] = get_float_element(array, i);
    }

    c_feed(n, input_array, output_array, 1);
    error = mean_square_error(n, output_array);

    free(input_array);
    free(output_array);

    return error;
}

int c_new_network(int input, int hidden, int output)
{
    NEURAL_NETWORK *n;
    int handle;

    handle = c_new_handle();
    n = c_get_network(handle);

    n->size.input  = input;
    n->size.hidden = hidden;
    n->size.output = output;

    if (!c_create_network(n))
        return -1;

    /* Perl already seeded the random number generator, via a rand(1) call */

    c_assign_random_weights(n);

    return handle;
}

double c_train_set(int handle, SV* set, int iterations, double mse)
{
    NEURAL_NETWORK *n = c_get_network(handle);
    AV     *input_array, *output_array; /* perl arrays */
    double *input, *output; /* C arrays */
    double max_error = 0.0;

    int set_length=0;
    int i,j;
    int index;

    set_length = av_len(get_array(set))+1;

    if (!set_length)
        croak("_train_set() array ref has no data");
    if (set_length % 2)
        croak("_train_set array ref must have an even number of elements");

    /* allocate memory for out input and output arrays */
    input_array    = get_array_from_aoa(set, 0);
    input          = malloc(sizeof(double) * set_length * (av_len(input_array)+1));

    output_array    = get_array_from_aoa(set, 1);
    output          = malloc(sizeof(double) * set_length * (av_len(output_array)+1));

    for (i=0; i < set_length; i += 2) {
        input_array = get_array_from_aoa(set, i);
        
        if (av_len(input_array)+1 != n->size.input)
            croak("Length of input data does not match");
        
        /* iterate over the input_array and assign the floats to input */
        
        for (j = 0; j < n->size.input; j++) {
            index = (i/2*n->size.input)+j;
            input[index] = get_float_element(input_array, j); 
        }
        
        output_array = get_array_from_aoa(set, i+1);
        if (av_len(output_array)+1 != n->size.output)
            croak("Length of output data does not match");

        for (j = 0; j < n->size.output; j++) {
            index = (i/2*n->size.output)+j;
            output[index] = get_float_element(output_array, j); 
        }
    }

    for (i = 0; i < iterations; i++) {
        max_error = 0.0;

        for (j = 0; j < (set_length/2); j++) {
            double error;

            c_feed(n, &input[j*n->size.input], &output[j*n->size.output], 1);

            if (mse >= 0.0 || i == iterations - 1) {
                error = mean_square_error(n, &output[j*n->size.output]);
                if (error > max_error)
                    max_error = error;
            }
        }

        if (mse >= 0 && max_error <= mse)    /* Below their target! */
            break;
    }

    free(input);
    free(output);

    return max_error;
}

SV* c_infer(int handle, SV *array_ref)
{
    NEURAL_NETWORK *n = c_get_network(handle);
    int    i;
    AV     *perl_array, *result = newAV();

    /* feed the data */
    perl_array = get_array(array_ref);

    for (i = 0; i < n->size.input; i++)
        n->tmp[i] = get_float_element(perl_array, i);

    c_feed(n, n->tmp, NULL, 0); 

    /* read the results */
    for (i = 0; i < n->size.output; i++) {
        av_push(result, newSVnv(n->neuron.output[i]));
    }
    return newRV_noinc((SV*) result);
}

void c_feed(NEURAL_NETWORK *n, double *input, double *output, int learn)
{
    int i;

    for (i=0; i < n->size.input; i++) {
        n->neuron.input[i]  = input[i];
    }

    if (learn)
        for (i=0; i < n->size.output; i++)
            n->neuron.target[i] = output[i];

    c_feed_forward(n);

    if (learn) c_back_propagate(n); 
}

/*
 *  The original author of this code is M. Tim Jones <mtj@cogitollc.com> and
 *  written for the book "AI Application Programming", by Charles River Media.
 *
 *  It's been so heavily modified that it bears little resemblance to the
 *  original, but credit should be given where credit is due.  Therefore ...
 *
 *  Copyright (c) 2003 Charles River Media.  All rights reserved.
 * 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, is hereby granted without fee provided that the following
 *  conditions are met:
 * 
 *    1.  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.  2.
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.  3.
 *    Neither the name of Charles River Media nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY CHARLES RIVER MEDIA AND CONTRIBUTORS 'AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL CHARLES RIVER MEDIA OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

MODULE = AI::NeuralNet::Simple	PACKAGE = AI::NeuralNet::Simple

PROTOTYPES: DISABLE

int
is_array_ref (ref)
	SV *	ref

AV *
get_array (aref)
	SV *	aref

float
get_float_element (array, index)
	AV *	array
	int	index

SV *
get_element (array, index)
	AV *	array
	int	index

AV *
get_array_from_aoa (aref, index)
	SV *	aref
	int	index

float
c_get_learn_rate (handle)
	int	handle

void
c_set_learn_rate (handle, rate)
	int	handle
	float	rate
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	c_set_learn_rate(handle, rate);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

double
c_get_delta (handle)
	int	handle

void
c_set_delta (handle, delta)
	int	handle
	double	delta
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	c_set_delta(handle, delta);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

int
c_get_use_bipolar (handle)
	int	handle

void
c_set_use_bipolar (handle, bipolar)
	int	handle
	int	bipolar
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	c_set_use_bipolar(handle, bipolar);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
c_destroy_network (handle)
	int	handle
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	c_destroy_network(handle);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

SV *
build_rv (av)
	AV *	av

SV *
build_axaref (arena, rows, columns)
	void *	arena
	int	rows
	int	columns

SV *
c_export_network (handle)
	int	handle

void
c_load_axa (hold, idx, arena, rows, columns)
	AV *	hold
	int	idx
	void *	arena
	int	rows
	int	columns
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	c_load_axa(hold, idx, arena, rows, columns);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

int
c_import_network (rv)
	SV *	rv

double
c_train (handle, input, output)
	int	handle
	SV *	input
	SV *	output

int
c_new_network (input, hidden, output)
	int	input
	int	hidden
	int	output

double
c_train_set (handle, set, iterations, mse)
	int	handle
	SV *	set
	int	iterations
	double	mse

SV *
c_infer (handle, array_ref)
	int	handle
	SV *	array_ref

