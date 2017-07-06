package AI::XGBoost;
use strict;
use warnings;

our $VERSION = '0.005';    # VERSION

# ABSTRACT: Perl wrapper for XGBoost library L<https://github.com/dmlc/xgboost>

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost - Perl wrapper for XGBoost library L<https://github.com/dmlc/xgboost>

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use 5.010;
 use AI::XGBoost::CAPI qw(:all);
 
 my $dtrain = XGDMatrixCreateFromFile('agaricus.txt.train');
 my $dtest = XGDMatrixCreateFromFile('agaricus.txt.test');
 
 my ($rows, $cols) = (XGDMatrixNumRow($dtrain), XGDMatrixNumCol($dtrain));
 say "Train dimensions: $rows, $cols";
 
 my $booster = XGBoosterCreate([$dtrain]);
 
 for my $iter (0 .. 10) {
     XGBoosterUpdateOneIter($booster, $iter, $dtrain);
 }
 
 my $predictions = XGBoosterPredict($booster, $dtest);
 # say join "\n", @$predictions;
 
 XGBoosterFree($booster);
 XGDMatrixFree($dtrain);
 XGDMatrixFree($dtest);

=head1 DESCRIPTION

Perl wrapper for XGBoost library. This version only wraps part of the C API.

The documentation can be found in L<AI::XGBoost::CAPI::RAW>

Currently this module need the xgboost binary available in your system. 
I'm going to make an Alien module for xgboost but meanwhile you need to
compile yourself xgboost: L<https://github.com/dmlc/xgboost>

=head1 ROADMAP

The goal is to make a full wrapper for XGBoost.

=head2 VERSIONS

=over 4

=item 0.1 

Full raw C API available as L<AI::XGBoost::CAPI::RAW>

=item 0.2 

Full C API "easy" to use, with PDL support as L<AI::XGBoost::CAPI>

Easy means clients don't have to use L<FFI::Platypus> or modules dealing
with C structures

=item 0.3

Object oriented API Moose based with DMatrix and Booster classes

=item 0.4

Complete object oriented API

=item 0.5

Use perl signatures (L<https://metacpan.org/pod/distribution/perl/pod/perlexperiment.pod#Subroutine-signatures>)

=back

=head1 SEE ALSO

=over 4

=item L<AI::MXNet>

=item L<FFI::Platypus>

=item L<NativeCall>

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
