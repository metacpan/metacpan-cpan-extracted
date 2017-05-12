package Clarity::XOG;
use App::Cmd::Setup -app;

sub usage_desc { "xogtool <subcommand> [options]* [files]*" }
sub abstract { "*** ABSTRACT *** ABSTRACT *** Clarity XOG utility" }

sub default_command { "commands" }

sub _usage_text {
"xogtool <subcommand> [options]* [files]*

  This is a Clarity XOG tool.
  Its primary usecase is merging XOG project files.
  See 'xogtool help merge' for more details.
",
}

1;

__END__

=pod

=head1 NAME

Clarity::XOG - xogtool utility base class

=head1 ABOUT

This is the base class for the C<xogtool> utility based on
L<App::Command|App::Command>.

=head1 AUTHOR

Steffen Schwigon, C<< <ss5 at renormalist.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-clarity-xog-merge
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clarity-XOG-Merge>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
