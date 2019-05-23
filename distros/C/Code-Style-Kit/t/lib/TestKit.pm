package TestKit;
use parent qw(Code::Style::Kit
              TestKit::Parts::Strictures
              TestKit::Parts::Methods
              TestKit::Parts::List
              TestKit::Parts::Args);

sub feature_strict_default { 0 }

1;
