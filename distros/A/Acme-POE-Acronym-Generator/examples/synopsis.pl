  use strict;
  use Acme::POE::Acronym::Generator;

  my $poegen = Acme::POE::Acronym::Generator->new();

  for ( 1 .. 10 ) {
    my $acronym = $poegen->generate();
    print $acronym, "\n";
  }
