package DB::Pluggable::Dumper;

use strict;
use warnings;
use 5.008;
use Data::Dumper ();

use parent 'DB::Pluggable::Plugin';

my $eval = \&DB::eval;

sub register {
    my ( $self, $context ) = @_;
    $self->make_command( xx => sub { }, );
}

# XXX I couldn't make this work by pushing the eval override into
# DB::Pluggable :(
{
    package    # hide from pause
      DB;
    *eval = sub {
        if ( $DB::evalarg =~ s/\n\s*xx\s+([^\n]+)$/\n $1/ ) {
            no warnings 'redefine';
            local $DB::onetimeDump = 'dump';    # main::dumpvar shows the output
            local *DB::dumpit = sub {
                my ( $fh, $res ) = @_;
                my $dd = Data::Dumper->new( [] );
                $dd->Terse(1)->Indent(1)->Useqq(1)->Deparse(1)->Quotekeys(0)
                  ->Sortkeys(1);
                print $fh $dd->Values($res)->Dump;
            };
            $eval->();
        }
        else {
            $eval->();
        }
    };
}

1;

=head1 NAME

DB::Pluggable::Dumper - Add 'xx' dumper to debugger

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

In your C<$HOME/.perldb>:

    #!/usr/bin/env perl

    use DB::Pluggable;
    use YAML;

    $DB::PluginHandler = DB::Pluggable->new( config => Load <<'END');
    global:
      log:
        level: error

    plugins:
      - module: Dumper
    END

    $DB::PluginHandler->run;

=head1 DESCRIPTION

This module adds the C<xx> command to the debugger.  It's like the C<x>
command, but outputs pretty L<Data::Dumper> format.  Here's the output of a
data structure with 'x':

    auto(-2)  DB<2> x $before
    0  HASH(0x100e7e8f0)
       'aref' => ARRAY(0x1009000d8)
          0  1
          1  2
          2  4
       'guess' => CODE(0x100829568)
          -> &main::testit in run.pl:3-6
       'uno' => HASH(0x100803108)
          'this' => 'that'
          'what?' => HASH(0x100e3d508)
             'this' => 'them'

Here's the same data structure with 'xx':

    auto(-1)  DB<3> xx $after
    {
      aref => [
        1,
        2,
        4
      ],
      guess => sub {
          my $x = shift @_;
          return $x + 1;
      },
      uno => {
        this => "that",
        "what?" => {
          this => "them"
        }
      }
    }

Which would you rather debug?

=head1 TODO

=over 4

=item * Add support for L<Data::Dump::Streamer>.

=item * Push the eval hack back into L<DB::Pluggable>.

=item * Allow control over dumper configuration.

=back

=head1 SEE ALSO

=over 4

=item * L<DB::Pluggable>

Marcel Grünauer wrote this to add plugin support to the Perl debugger.  Has
L<DB::Pluggable::BreakOnTestNumber> and L<DB::Pluggable::TypeAhead> included.

=item * L<DB::Pluggable::StackTraceAsHTML>

Adds a 'C<Th>' command to the debugger.  Opens up a strack trace in your
browswer, complete with lexicals.

=head1 NOTE

This code is an awful hack because the perl debugger (C<perl5db.pl>) is an
awful hack.  My apologies.

=back

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-db-pluggable-dumper at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Pluggable-Dumper>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DB::Pluggable::Dumper

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Pluggable-Dumper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DB-Pluggable-Dumper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DB-Pluggable-Dumper>

=item * Search CPAN

L<http://search.cpan.org/dist/DB-Pluggable-Dumper/>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Marcel Grünauer (for L<DB::Pluggable>)

=item * Matt Trout (for L<Data::Dumper::Concise>)

=item * Vienna.pm, for sponsoring the 2010 Perl QA Hackathon

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of DB::Pluggable::Dumper
