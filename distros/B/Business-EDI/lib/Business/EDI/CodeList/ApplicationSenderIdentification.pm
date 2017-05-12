package Business::EDI::CodeList::ApplicationSenderIdentification;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0040";}
my $usage       = 'B';  # guessed value

# 0040 Application sender identification                                    []
# Desc: 
# Repr: 
my %code_hash = (

);
sub get_codes { return \%code_hash; }

1;
