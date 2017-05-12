package Reply::Plugin::ddGUI;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$Reply::Plugin::ddGUI::AUTHORITY = 'cpan:TOBYINK';
	$Reply::Plugin::ddGUI::VERSION   = '0.006';
}

use parent qw( Reply::Plugin );
use ddGUI qw( Dumper );

sub execute {
	my $self = shift;
	my ($next, @args) = @_;
	@{ $self->{results} = [$next->(@args)] };
}

sub command_gui {
	Dumper @{$_[0]{results}};
	return 1;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords ddGUI

=head1 NAME

Reply::Plugin::ddGUI - use Data::Dumper::GUI with Reply

=head1 SYNOPSIS

   ; .replyrc
   [ddGUI]

=head1 DESCRIPTION

This is a plugin for L<Reply> allowing you to inspect the last result
using L<Data::Dumper::GUI>. After an interesting result, just type
C<< #gui >> to open it up in a window.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Data-Dumper-GUI>.

=head1 SEE ALSO

L<Data::Dumper::GUI>, L<Reply>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

