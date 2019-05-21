package CTK::Plugin::CLI;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::CLI - CLI plugin

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use CTK;
    my $ctk = new CTK(
            plugins => "cli",
        );
    print $ctk->cli_prompt;

=head1 DESCRIPTION

Command-Line Interface plugin

=head1 METHODS

=over 8

=item B<cli_prompt>

    my $v = $ctk->cli_prompt('Your name:', 'anonymous');
    debug( "Your name: $v" );

Show prompt string for typing data

See L<CTK::CLI/"cli_prompt">

=item B<cli_select>

    my $v = $ctk->cli_select('Your select:',[qw/foo bar baz/],'bar');
    debug( "Your select: $v" );

Show prompt string for select item

See L<CTK::CLI/"cli_select">

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<CTK::CLI>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<CTK::CLI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/CTK::Plugin/;

use CTK::CLI qw/cli_prompt cli_select/;

__PACKAGE__->register_method(
    method    => "cli_prompt",
    callback  => sub { cli_prompt(@_) }
);

__PACKAGE__->register_method(
    method    => "cli_select",
    callback  => sub { cli_select(@_) }
);

1;

__END__
