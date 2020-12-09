package Data::CompactReadonly::Dictionary;
our $VERSION = '0.0.3';
sub use_base_is_buggy_and_insists_that_there_be_something_here {}
1;

# empty package that exists only so that D::C::V*::Dictionary can inherit
# from it and you can check that something ->isa('Data::CompactReadonly::Dictionary');
