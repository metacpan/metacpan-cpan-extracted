## no critic: Modules::ProhibitAutomaticExportation

package DD;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-08-12'; # DATE
our $DIST = 'DD-Dummy'; # DIST
our $VERSION = '0.007'; # VERSION

use Exporter qw(import);
our @EXPORT = qw(dd dd_warn dd_die dmp);

our $BACKEND = $ENV{PERL_DD_BACKEND} || "Data::Dump";

our $_action;

sub _doit {
    if      ($BACKEND eq 'Data::Dmp') {
        require Data::Dmp;
        if    ($_action eq 'dd'     ) { goto  &Data::Dmp::dd                      }
        elsif ($_action eq 'dd_warn') { warn   Data::Dmp::dmp(@_)."\n"; return @_ }
        elsif ($_action eq 'dd_die' ) { warn   Data::Dmp::dmp(@_)."\n"; return @_ }
        elsif ($_action eq 'dmp'    ) { goto  &Data::Dmp::dmp                     }
    } elsif ($BACKEND eq 'Data::Dump') {
        require Data::Dump;
        if    ($_action eq 'dd'     ) { print  Data::Dump::dump(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Dump::dump(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Dump::dump(@_). "\n"            }
        elsif ($_action eq 'dmp'    ) { return Data::Dump::dump(@_)                  }
    } elsif ($BACKEND eq 'Data::Dump::Color') {
        require Data::Dump::Color;
        if    ($_action eq 'dd'     ) { print  Data::Dump::Color::dump(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Dump::Color::dump(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Dump::Color::dump(@_). "\n"            }
        elsif ($_action eq 'dmp'    ) { return Data::Dump::Color::dump(@_)                  }
    } elsif ($BACKEND eq 'Data::Dump::PHP') {
        require Data::Dump::PHP;
        if    ($_action eq 'dd'     ) { print  Data::Dump::PHP::dump(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Dump::PHP::dump(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Dump::PHP::dump(@_). "\n"            }
        elsif ($_action eq 'dmp'    ) { return Data::Dump::PHP::dump(@_)                  }
    } elsif ($BACKEND eq 'Data::Dumper') {
        require Data::Dumper;
        local $Data::Dumper::Terse     = 1;
        local $Data::Dumper::Indent    = 1;
        local $Data::Dumper::Useqq     = 1;
        local $Data::Dumper::Deparse   = 1;
        local $Data::Dumper::Quotekeys = 0;
        local $Data::Dumper::Sortkeys  = 1;
        if    ($_action eq 'dd'     ) { print  Data::Dumper::Dumper(@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Dumper::Dumper(@_); return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Dumper::Dumper(@_)            }
        elsif ($_action eq 'dmp'    ) { return Data::Dumper::Dumper(@_)            }
    } elsif ($BACKEND eq 'Data::Dumper::Compact') {
        require Data::Dumper::Compact;
        if    ($_action eq 'dd'     ) { print  Data::Dumper::Compact->new()->dump(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Dumper::Compact->new()->dump(\@_); return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Dumper::Compact->new()->dump(\@_)            }
        elsif ($_action eq 'dmp'    ) { return Data::Dumper::Compact->new()->dump(\@_)            }
    } elsif ($BACKEND eq 'Data::Format::Pretty::Console') {
        require Data::Format::Pretty::Console;
        if    ($_action eq 'dd'     ) { print  Data::Format::Pretty::Console::format_pretty(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Format::Pretty::Console::format_pretty(\@_); return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Format::Pretty::Console::format_pretty(\@_)            }
        elsif ($_action eq 'dmp'    ) { return Data::Format::Pretty::Console::format_pretty(\@_)            }
    } elsif ($BACKEND eq 'Data::Format::Pretty::SimpleText') {
        require Data::Format::Pretty::SimpleText;
        if    ($_action eq 'dd'     ) { print  Data::Format::Pretty::SimpleText::format_pretty(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Format::Pretty::SimpleText::format_pretty(\@_); return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Format::Pretty::SimpleText::format_pretty(\@_)            }
        elsif ($_action eq 'dmp'    ) { return Data::Format::Pretty::SimpleText::format_pretty(\@_)            }
    } elsif ($BACKEND eq 'Data::Format::Pretty::Text') {
        require Data::Format::Pretty::Text;
        if    ($_action eq 'dd'     ) { print  Data::Format::Pretty::Text::format_pretty(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   Data::Format::Pretty::Text::format_pretty(\@_); return @_ }
        elsif ($_action eq 'dd_die' ) { die    Data::Format::Pretty::Text::format_pretty(\@_)            }
        elsif ($_action eq 'dmp'    ) { return Data::Format::Pretty::Text::format_pretty(\@_)            }
    } elsif ($BACKEND eq 'Data::Printer') {
        require Data::Printer;
        if    ($_action eq 'dd'     ) { my ($out, $p) = Data::Printer::_data_printer(1, \@_, colored=>1); print $out."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { my ($out, $p) = Data::Printer::_data_printer(1, \@_, colored=>1); warn  $out."\n"; return @_ }
        elsif ($_action eq 'dd_die' ) { my ($out, $p) = Data::Printer::_data_printer(1, \@_, colored=>1); die   $out."\n"            }
        elsif ($_action eq 'dmp'    ) { return Data::Printer::np(@_) }
    } elsif ($BACKEND eq 'JSON::Color') {
        require JSON::Color;
        if    ($_action eq 'dd'     ) { print  JSON::Color::encode_json(\@_)."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   JSON::Color::encode_json(\@_)."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { die    JSON::Color::encode_json(\@_)."\n"            }
        elsif ($_action eq 'dmp'    ) { return JSON::Color::encode_json(\@_)                 }
    } elsif ($BACKEND eq 'JSON::MaybeXS') {
        require JSON::MaybeXS;
        if    ($_action eq 'dd'     ) { print  JSON::MaybeXS::encode_json(\@_)."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   JSON::MaybeXS::encode_json(\@_)."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { die    JSON::MaybeXS::encode_json(\@_)."\n"            }
        elsif ($_action eq 'dmp'    ) { return JSON::MaybeXS::encode_json(\@_)                 }
    } elsif ($BACKEND eq 'JSON::PP') {
        require JSON::PP;
        if    ($_action eq 'dd'     ) { print  JSON::PP::encode_json(\@_)."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   JSON::PP::encode_json(\@_)."\n"; return @_ }
        elsif ($_action eq 'dd_warn') { die    JSON::PP::encode_json(\@_)."\n"            }
        elsif ($_action eq 'dmp'    ) { return JSON::PP::encode_json(\@_)                 }
    } elsif ($BACKEND eq 'PHP::Serialization') {
        require PHP::Serialization;
        if    ($_action eq 'dd'     ) { print  PHP::Serialization::serialize(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_warn') { warn   PHP::Serialization::serialize(@_). "\n"; return @_ }
        elsif ($_action eq 'dd_die' ) { die    PHP::Serialization::serialize(@_). "\n"            }
        elsif ($_action eq 'dmp'    ) { return PHP::Serialization::serialize(@_)                  }
    } elsif ($BACKEND eq 'YAML') {
        require YAML;
        if    ($_action eq 'dd'     ) { print  YAML::Dump(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   YAML::Dump(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { die    YAML::Dump(\@_)            }
        elsif ($_action eq 'dmp'    ) { return YAML::Dump(\@_)            }
    } elsif ($BACKEND eq 'YAML::Tiny::Color') {
        require YAML::Tiny::Color;
        if    ($_action eq 'dd'     ) { print  YAML::Tiny::Color::Dump(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { warn   YAML::Tiny::Color::Dump(\@_); return @_ }
        elsif ($_action eq 'dd_warn') { die    YAML::Tiny::Color::Dump(\@_)            }
        elsif ($_action eq 'dmp'    ) { return YAML::Tiny::Color::Dump(\@_)            }
    } else {
        die "DD: Unknown backend '$BACKEND'";
    }
}

sub dd      { $_action = 'dd';      goto &_doit }
sub dd_warn { $_action = 'dd_warn'; goto &_doit }
sub dd_die  { $_action = 'dd_die';  goto &_doit }
sub dmp     { $_action = 'dmp';     goto &_doit }

1;
# ABSTRACT: Dump data structure for debugging

__END__

=pod

=encoding UTF-8

=head1 NAME

DD - Dump data structure for debugging

=head1 VERSION

This document describes version 0.007 of DD (from Perl distribution DD-Dummy), released on 2019-08-12.

=head1 SYNOPSIS

To install this module, currently do this:

 % cpanm -n DD::Dummy

In your code:

 use DD; # exports dd(), dd_warn(), dd_die(), dmp()
 ...
 dd $data                ; # prints data to STDOUT, return argument
 my $foo = dd $data      ; # ... so you can use it inside expression
 my $foo = dd_warn $data ; # just like dd() but warns instead
 dd_die $data            ; # just like dd() but dies instead

 my $dmp = dmp $data     ; # dump data as string and return it

On the command-line:

 % perl -MDD -E'...; dd $data; ...'

=head1 DESCRIPTION

C<DD> is a module with a short name you can use for debugging. It provides
L</dd> which dumps data structure to STDOUT, as well as return the original data
so you can insert C<dd> in the middle of expressions. It also provides
L</dd_warn>, L</dd_die>, as well as L</dmp> for completeness.

C<DD> can use several kinds of backends. The default is L<Data::Dump> which is
chosen because it's a mature module and produces visually nice dumps for
debugging. You can also use these other backends:

=over

=item * L<Data::Dmp>

Optional dependency. Compact output.

=item * L<Data::Dump::Color>

Optional dependency. Colored output.

=item * L<Data::Dump::PHP>

Optional dependency.

See also: L<PHP::Serialization>.

=item * L<Data::Dumper>

Optional dependency. A core module.

=item * L<Data::Dumper::Compact>

Optional dependency.

=item * L<Data::Format::Pretty::Console>

Optional dependency. Colored output.

=item * L<Data::Format::Pretty::SimpleText>

Optional dependency.

=item * L<Data::Format::Pretty::Text>

Optional dependency. Colored output.

=item * L<Data::Printer>

Optional dependency. Colored output.

=item * L<JSON::Color>

Optional dependency. Colored output.

Note that the JSON format cannot handle some kinds of Perl data (e.g. typeglobs,
recursive structure). You might want to "clean" the data first before dumping
using L<Data::Clean::ForJSON>.

=item * L<JSON::MaybeXS>

Optional dependency.

Note that the JSON format cannot handle some kinds of Perl data (e.g. typeglobs,
recursive structure). You might want to "clean" the data first before dumping
using L<Data::Clean::ForJSON>.

=item * L<JSON::PP>

Optional dependency, a core module.

Note that the JSON format cannot handle some kinds of Perl data (e.g. typeglobs,
recursive structure). You might want to "clean" the data first before dumping
using L<Data::Clean::ForJSON>.

=item * L<PHP::Serialization>

Optional dependency. Compact output.

See also: L</Data::Dump::PHP>.

=item * L<YAML>

Optional dependency.

=item * L<YAML::Tiny::Color>

Optional dependency. Colored output.

Note that this dumper cannot handle some kinds of Perl data (e.g. recursive
references). You might want to "clean" the data first before dumping using
L<Data::Clean> or L<Data::Clean::ForJSON>.

=back

=head1 PACKAGE VARIABLES

=head2 $BACKEND

The backend to use. The default is to use L</PERL_DD_BACKEND> environment
variable or "Data::Dump" as the fallback default.

=head1 FUNCTIONS

=head2 dd

Print the dump of its arguments to STDOUT, and return its arguments.

=head2 dd_warn

Warn the dump of its arguments, and return its arguments. If you want a full
stack trace, you can use L<Devel::Confess>, e.g. on the command-line:

 % perl -d:Confess -MDD -E'... dd_warn $data;'

=head2 dd_die

Die with the dump of its arguments as message. If you want a full stack trace,
you can use L<Devel::Confess>, e.g. on the command-line:

 % perl -d:Confess -MDD -E'... dd_die $data;'

=head2 dmp

Dump its arguments as string and return it.

=head1 ENVIRONMENT

=head2 PERL_DD_BACKEND

Can be used to set the default backend.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DD-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DD-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DD-Dummy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<XXX> - basically the same thing but with different function names and
defaults. I happen to use "XXX" to mark todo items in source code, so I prefer
other names.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
