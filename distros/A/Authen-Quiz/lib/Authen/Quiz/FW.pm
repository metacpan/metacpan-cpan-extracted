package Authen::Quiz::FW;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FW.pm 362 2008-08-18 18:34:11Z lushe $
#
use strict;
use warnings;
use Class::C3;
use UNIVERSAL::require;
use Authen::Quiz;

our $VERSION= '0.01';

our @ISA;

my @plugins;
sub plugins { \@plugins }

sub import {
	my $class= shift;
	for (@_) {
		my $pkg= /^\+(.+)/ ? $1: "Authen::Quiz::Plugin::$_";
		push @plugins, $pkg;
		push @ISA, $pkg;
	}
	push @ISA, 'Authen::Quiz';
	push @ISA, 'Authen::Quiz::FW::Base';
	for my $load (@plugins) { $load->require || die __PACKAGE__. " - $@" }
	$class->_setup;
}

package Authen::Quiz::FW::Base;
use strict;
sub _setup { @_ }

1;

__END__

=head1 NAME

Authen::Quiz::FW - Framework for Authen::Quiz.

=head1 SYNOPSIS

  use Authen::Quiz::FW qw/ JS Memcached /;
  
  my $q= Authen::Quiz::FW->new(
    data_folder => '/path/to/authen_quiz',
    memcached   => { ...... },
    );
  
  my $js_source= $q->question2js('boxid');

=head1 DESCRIPTION

The framework for L<Authen::Quiz> makes the plugin available.

If use passes the list of the plugin at the time of reading Authen::Quiz::FW, it becomes available.

  use Authen::Quiz::FW qw/ JS Memcached /;

L<Authen::Quiz::Plugin::JS> and L<Authen::Quiz::Plugin::Memcached> was enclosed as a standard plugin.

=head1 METHODS

=head2 plugins

The list of the read plug-in is returned.

=head1 SEE ALSO

L<Authen::Quiz>,
L<UNIVERSAL::require>,
L<Class::C3>,

L<http://egg.bomcity.com/wiki?Authen%3a%3aQuiz>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
