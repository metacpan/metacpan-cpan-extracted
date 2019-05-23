package TestKit::Parts::Strictures;

sub feature_strict_default { 1 }
sub feature_strict_export { strict->import }
sub feature_strict_order { 1 }  # export this first

sub feature_fatal_warnings_default { 1 }
sub feature_fatal_warnings_export {
    require warnings;
    warnings->import(FATAL=>'all');
}

1;
