package Alien::LIBSVM;
# ABSTRACT: Alien package for the LIBSVM library
$Alien::LIBSVM::VERSION = '0.005';
use strict;
use warnings;

use parent 'Alien::Base';

sub version {
	my ($class) = @_;

	( "" . $class->SUPER::version) =~ s/^\d/$&./gr;
}

sub inline_auto_include {
	return  [ "svm.h" ];
}
sub libs {
	my ($class) = @_;

	join ' ', (
		$class->install_type eq 'share' ? ('-L' . File::Spec->catfile($class->dist_dir, qw(lib)) ) : (),
		'-lsvm',
	);
}

sub cflags {
	my ($class) = @_;
	join ' ', (
		$class->install_type eq 'share' ? ('-I' . File::Spec->catfile($class->dist_dir, qw(include)) ) : (),
	);
}

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $params = Alien::Base::Inline(@_);
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::LIBSVM - Alien package for the LIBSVM library

=head1 VERSION

version 0.005

=head1 METHODS

=head2 svm_train_path

Path to the C<svm-train> executable.

=head2 svm_predict_path

Path to the C<svm-predict> executable.

=head2 svm_scale_path

Path to the C<svm-scale> executable.

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
