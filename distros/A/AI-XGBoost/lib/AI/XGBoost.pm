package AI::XGBoost;
use strict;
use warnings;

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Perl wrapper for XGBoost library https://github.com/dmlc/xgboost

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost - Perl wrapper for XGBoost library https://github.com/dmlc/xgboost

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use 5.010;
 use AI::XGBoost::CAPI;
 use FFI::Platypus;
 
 my $silent = 0;
 my ($dtrain, $dtest) = (0, 0);
 
 AI::XGBoost::CAPI::XGDMatrixCreateFromFile('agaricus.txt.test', $silent, \$dtest);
 AI::XGBoost::CAPI::XGDMatrixCreateFromFile('agaricus.txt.train', $silent, \$dtrain);
 
 my ($rows, $cols) = (0, 0);
 AI::XGBoost::CAPI::XGDMatrixNumRow($dtrain, \$rows);
 AI::XGBoost::CAPI::XGDMatrixNumCol($dtrain, \$cols);
 say "Dimensions: $rows, $cols";
 
 my $booster = 0;
 
 AI::XGBoost::CAPI::XGBoosterCreate( [$dtrain] , 1, \$booster);
 
 for my $iter (0 .. 10) {
     AI::XGBoost::CAPI::XGBoosterUpdateOneIter($booster, $iter, $dtrain);
 }
 
 my $out_len = 0;
 my $out_result = 0;
 
 AI::XGBoost::CAPI::XGBoosterPredict($booster, $dtest, 0, 0, \$out_len, \$out_result);
 my $ffi = FFI::Platypus->new();
 my $predictions = $ffi->cast(opaque => "float[$out_len]", $out_result);
 
 #say join "\n", @$predictions;
 
 AI::XGBoost::CAPI::XGBoosterFree($booster);

=head1 DESCRIPTION

Perl wrapper for XGBoost library. This version only wraps the C API.

The documentation can be found in L<AI::XGBoost::CAPI>

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
