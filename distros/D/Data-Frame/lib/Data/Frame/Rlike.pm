package Data::Frame::Rlike;
$Data::Frame::Rlike::VERSION = '0.003';
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(dataframe factor);

use Data::Frame;
use PDL::Factor;

our $_df_rlike_class = Moo::Role->create_class_with_roles( 'Data::Frame',
	qw(Data::Frame::Role::Rlike));

sub dataframe {
	$_df_rlike_class->new( columns => \@_ );
}

sub factor {
	PDL::Factor->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Rlike

=head1 VERSION

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
