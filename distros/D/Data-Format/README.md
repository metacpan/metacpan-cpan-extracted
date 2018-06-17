# Data::Format
Data::Format is my Perl module to format data

## Instalation

Standard process for building & installing modules:

<pre>

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

</pre>

Or, if you're on a platform (like DOS or Windows) that doesn't require the "./" notation, you can do this:

<pre>

  perl Build.PL
  Build
  Build test
  Build install

</pre>

## Examples

### Sanitize data

#### Numbers

##### Money
<pre>
  
  use Data::Format::Sanitize::Number ':money';

  money 385.00;                     # '385,00'
  money 385000;                     # '385.000,00'
  money 3850000;                    # '3.850.000,00'
  money 3850000.5;                  # '3.850.000,5'
  money 3850000.56;                 # '3.850.000,56'
  money 3850000.56665;              # '3.850.000,56665'
  
  money_integer 385;                # '385'
  money_integer 385000;             # '385.000'
  money_integer 3850000;            # '3.850.000'
  money_integer 3850000.00;         # '3.850.000'
  money_integer 3850000.5646;       # '3.850.000'
  
  money_decimal;                    # ',00'
  money_decimal 385;                # ',385'
  money_decimal 5465564;            # ',5465564'

  money_to_int '385,00';            # 385.00
  money_to_int '385.000,00';        # 385000
  money_to_int '3.850.000,00';      # 3850000
  money_to_int '3.850.000,5';       # 3850000.5
  money_to_int '3.850.000,56';      # 3850000.56
  money_to_int '3.850.000,56665';   # 3850000.56665
</pre>

### Validate data

#### Numbers

##### Money
<pre>
  
  use Data::Format::Validate::Number ':money';

  looks_like_money '3.850.000,5';   # 1
  looks_like_money '3.850.000,56';  # 1
  looks_like_money '385,,00';       # 0
  looks_like_money '3e85,0e0';      # 0

</pre>

#### Strings

##### IP(ipv4)
<pre>
  
  use Data::Format::Validate::String ':ip';

  looks_like_ipv4 '127.0.0.1';        # 1
  looks_like_ipv4 '192.168.0.1';      # 1
  looks_like_ipv4 '255.255.255.255';  # 1

  looks_like_ipv4 '255255255255';     # 0
  looks_like_ipv4 '255.255.255.256';  # 0

</pre>