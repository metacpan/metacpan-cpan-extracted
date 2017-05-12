package Alien::LIBSVM;
$Alien::LIBSVM::VERSION = '0.003';
use strict;
use warnings;

use parent 'Alien::Base';

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $self = __PACKAGE__->new;
	+{
		LIBS => $self->libs,
		INC => $self->cflags,
		AUTO_INCLUDE => q|

#include "svm.h"

|
	};
}

sub svm_train_path {
  my ($self) = @_;
  File::Spec->catfile( $self->dist_dir , 'bin', 'svm-train' );
}

sub svm_predict_path {
  my ($self) = @_;
  File::Spec->catfile( $self->dist_dir , 'bin', 'svm-predict' );
}

sub svm_scale_path {
  my ($self) = @_;
  File::Spec->catfile( $self->dist_dir , 'bin', 'svm-scale' );
}

1;
# ABSTRACT: Alien package for the LIBSVM library

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::LIBSVM - Alien package for the LIBSVM library

=head1 VERSION

version 0.003

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<LIBSVM|http://www.csie.ntu.edu.tw/~cjlin/libsvm/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
