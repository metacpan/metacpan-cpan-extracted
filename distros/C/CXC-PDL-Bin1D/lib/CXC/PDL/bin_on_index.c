<%

{
    # Kahan compensated summation
    package ksum;

    use String::Interpolate::RE 'strinterp', { opts => { useENV => 0, recurse => 1 } };

    sub initialize {
        my $name = shift;
        my $loop = shift;

        return fmt( { name => $name, loop => $loop },
            q<
             PDL_COMMENT( "initialize Kahan Summation for $name" );
             loop($loop) %{ $sum   = 0.0; %}
             loop($loop) %{ $error = 0.0; %}
             >
        );
    }

    sub add {
        my ( $name, $args, $expr ) = @_;

        return fmt( {
                name => $name,
                expr => $expr,
                args => $args,
            },
            q<{
                PDL_COMMENT( "Kahan Summation increment for $name" );
                double temp = $sum;
                /* use temporaries to minimize access of piddle arrays */
                double y = ($expr) + $error;
                double tsum = temp + y;
                $sum = tsum;
                $error = ( temp - tsum ) + y;
              }
            >
        );
    }

    sub finalize {
        my ( $name, $loop) = @_;

        return fmt( {
                name => $name,
                loop => $loop,
            },
            q<{
             loop($loop) %{ $sum += $error; %}
              }
            >
        );
    }

    sub fmt {
        my $vars = 'HASH' eq ref $_[0] ? shift : {};

        return join "\n", map {
            strinterp(
                $_,
                {
                    sum   => q[$${name}($args)],
                    error => q[$${name}_error($args)],
                    args => '',
                    %$vars
                } )
        } @_;
    }
}

%>


<%
if ( $PDL_Indx ne "PDL_Indx" ) {"
typedef $PDL_Indx PDL_Indx;
"}
%>

int flags = $COMP(optflags);

int have_weight = flags & BIN_ARG_HAVE_WEIGHT;
int save_oob    = flags & BIN_ARG_SAVE_OOB;

threadloop %{

    PDL_Indx nbins = $nbins(nt => 0);
    PDL_Indx imin = $imin(nt => 0);
    PDL_Indx imax = imin + nbins - 1;

    /* if first bin is reserved for oob, need to
       offset imin to ensure that non-oob data start
       at second bin */
    if ( save_oob & BIN_ARG_SHIFT_IMIN )
      imin -= 1;

    /*  intialize output and temp bin data one at a time to
        avoid trashing the cache */
    <%  ksum::initialize( b_data => 'nb' ) %>;
    loop(nb) %{ $b_count()  = 0; %}
    loop(nb) %{ $b_mean() = 0; %}
    loop(nb) %{ $b_dev2() = 0; %}

    if ( have_weight ) {
      <%  ksum::initialize( b_weight => 'nb' ) %>;
      <%  ksum::initialize( b_weight2 => 'nb' ) %>;
    }

  /* if we could preset min & max to the initial value in a bin,
     we could shave off a comparison.  Unfortunately, we can't
     do that, as we can't know apriori which is the first
     element in a bin. */
    loop(nb) %{ $b_dmin() =  DBL_MAX; %}
    loop(nb) %{ $b_dmax() = -DBL_MAX; %}

  loop(n) %{

    PDL_Indx count;
    PDL_Indx idx = $index();
    double data = $data();
    double weight;

    PDL_Indx oob_low =
        save_oob & (BIN_ARG_SAVE_OOB_START_END | BIN_ARG_SAVE_OOB_START_NBINS ) ? 0
      : save_oob & (BIN_ARG_SAVE_OOB_END                                      ) ? $SIZE(nb) - 2
      : save_oob & (BIN_ARG_SAVE_OOB_NBINS                                    ) ? nbins
      : -1; /* error */

    PDL_Indx oob_high =
        save_oob & (BIN_ARG_SAVE_OOB_START_END   | BIN_ARG_SAVE_OOB_END   ) ? $SIZE(nb) - 1
      : save_oob & (BIN_ARG_SAVE_OOB_START_NBINS | BIN_ARG_SAVE_OOB_NBINS ) ? nbins + 1
      : -1; /*  error */


#ifdef PDL_BAD_CODE
    if (   $ISBADVAR(data,data)
        || $ISBADVAR(idx,index)
         ) {
      continue;
    }
#endif /* PDL_BAD_CODE */

    if ( have_weight ) {
      weight = $weight();

#ifdef PDL_BAD_CODE
      if ( $ISBADVAR(weight,weight) )
        continue;
#endif /* PDL_BAD_CODE */
    }


    if ( idx < imin ) {
      if ( save_oob ) idx = oob_low;
      else continue;
    }
    else if ( idx > imax ) {
      if ( save_oob ) idx = oob_high;
      else continue;
    }
    else {
      idx -= imin;
    }

    count = ++$b_count( nb => idx );
    /* $b_data( nb => idx ) += data; */

    if ( have_weight ){
      <% ksum::add( b_data => 'nb => idx', 'data * weight' ) %>;
    }
    else {
      <% ksum::add( b_data => 'nb => idx', 'data' ) %>;
    }

    if ( data < $b_dmin( nb => idx ) ) $b_dmin( nb => idx ) = data;
    if ( data > $b_dmax( nb => idx ) ) $b_dmax( nb => idx ) = data;

    {
      double prev_mean = $b_mean( nb => idx );
      double d_mean;

      if ( have_weight ) {
        double prev_sum_weight = $b_weight( nb => idx );

        <% ksum::add( b_weight => 'nb => idx', 'weight' ) %>;
        <% ksum::add( b_weight2 => 'nb => idx', 'weight * weight' ) %>;

        d_mean = weight * ( data - prev_mean ) / $b_weight( nb => idx );

        $b_mean( nb => idx ) += d_mean;
        $b_dev2( nb => idx ) += d_mean * ( data - prev_mean ) * prev_sum_weight;
      }

      else {
        d_mean = ( data - prev_mean ) / count;
        $b_mean( nb => idx ) +=  d_mean;
        $b_dev2( nb => idx ) += ( (count - 1) * ( data - prev_mean ) ) * d_mean;
      }
    }
  %}

  <% ksum::finalize( b_data => 'nb' ) %>;

  /* if there were no data in the bin, set some derived values to BAD_VAL */
  <% if ( $PDL::Bad::Status ) {'
  {
    /* if any are bad */
    int set_bad = 0;
    loop(nb) %{ if ( $b_count() == 0 ) { $SETBAD(b_dmin()); set_bad = 1;} %}

    if ( set_bad ) {
      $PDLSTATESETBAD(b_dmin);

      loop(nb) %{ if ( $b_count() == 0 ) { $SETBAD(b_dmax()); } %}
      $PDLSTATESETBAD(b_dmax);

      loop(nb) %{ if ( $b_count() == 0 ) { $SETBAD(b_mean()); } %}
      $PDLSTATESETBAD(b_mean);

      loop(nb) %{ if ( $b_count() == 0 ) { $SETBAD(b_dev2()); } %}
      $PDLSTATESETBAD(b_dev2);
    }
  }
  '}
  %>

  if ( have_weight ) {
      <% ksum::finalize( b_weight => 'nb' ) %>;
      <% ksum::finalize( b_weight2 => 'nb' ) %>;
  }

%}
