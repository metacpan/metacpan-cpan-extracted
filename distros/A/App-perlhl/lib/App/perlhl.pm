package App::perlhl;
use strict;
use warnings;
use v5.10.1;
no if ($] >= 5.017010), warnings => 'experimental::smartmatch';
use Syntax::Highlight::Perl::Improved 1.01 ();
use Term::ANSIColor 3.00 ();

# ABSTRACT: application class for syntax highlighting Perl source code
our $VERSION = '0.007'; # VERSION


sub new {
    my $class = shift;
    my $output= shift || 'ansi';

    my $formatter = Syntax::Highlight::Perl::Improved->new();
    given ($output) {
        when ('html') {
            my $color_table = {
                'Variable_Scalar'   => 'color:#080;',
                'Variable_Array'    => 'color:#f70;',
                'Variable_Hash'     => 'color:#80f;',
                'Variable_Typeglob' => 'color:#f03;',
                'Subroutine'        => 'color:#980;',
                'Quote'             => 'color:#00a;',
                'String'            => 'color:#00a;',
                'Comment_Normal'    => 'color:#069;font-style:italic;',
                'Comment_POD'       => 'color:#014;font-family:garamond,serif;font-size:11pt;',
                'Bareword'          => 'color:#3A3;',
                'Package'           => 'color:#900;',
                'Number'            => 'color:#f0f;',
                'Operator'          => 'color:#000;',
                'Symbol'            => 'color:#000;',
                'Keyword'           => 'color:#000;',
                'Builtin_Operator'  => 'color:#300;',
                'Builtin_Function'  => 'color:#001;',
                'Character'         => 'color:#800;',
                'Directive'         => 'color:#399;font-style:italic;',
                'Label'             => 'color:#939;font-style:italic;',
                'Line'              => 'color:#000;',
            };
            # HTML escapes.
            $formatter->define_substitution('<' => '&lt;',
                                            '>' => '&gt;',
                                            '&' => '&amp;');

            # install the formats set up above
            while ( my($type, $style) = each %{$color_table} ) {
                $formatter->set_format($type, [ qq{<span style="$style">}, qq{</span>} ]);
            }
        }
        when ('ansi') {
            my $color_table = { # Readability is not so good -- play with it more
                'Bareword'          => 'bright_green',
                'Builtin_Function'  => 'blue',
                'Builtin_Operator'  => 'bright_red',
                'Character'         => 'bold bright_red',
                'Comment_Normal'    => 'bright_blue',
                'Comment_POD'       => 'bright_black',
                'Directive'         => 'bold bright_black',
                'Keyword'           => 'white',
                'Label'             => 'bright_magenta',
                'Line'              => 'white',
                'Number'            => 'bright_red',
                'Operator'          => 'white',
                'Package'           => 'bold bright_red',
                'Quote'             => 'blue',
                'String'            => 'blue',
                'Subroutine'        => 'yellow',
                'Symbol'            => 'white',
                'Variable_Array'    => 'cyan',
                'Variable_Hash'     => 'magenta',
                'Variable_Scalar'   => 'green',
                'Variable_Typeglob' => 'bright_red',
            };

            # install the formats set up above
            while ( my ( $type, $style ) = each %{$color_table} ) {
                $formatter->set_format($type, [ Term::ANSIColor::color($style), Term::ANSIColor::color('reset') ]);
            }
        }
    }

    return bless { formatter => $formatter }, $class;
}


sub run {
    my $self  = shift;
    my $mode  = shift;
    my @files = @_;

    given ($mode) {
        when ('version')    { $self->_do_version(); }
        when ('highlight')  { $self->_do_highlighting(@files); }
        default             { $self->_do_highlighting(@files); }
    }
}

sub _do_version {
    my $this = __PACKAGE__;
    my $this_ver = (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev');
    say "$this version $this_ver" and exit;
}

sub _do_highlighting {
    my $self  = shift;
    my @files = @_;

    if (@files) {
        foreach my $filename (@files) {
            open my $in, '<', $filename;
            # Use a separate object for each file - otherwise,
            # highlighting for anything after the first file
            # will be suboptimal.
            my $formatter = $self->{formatter}->new();
            while (<$in>) {
                print $formatter->format_string;
            }
        }
    }
    else {
        while (<STDIN>) {
            print $self->{formatter}->format_string while (<STDIN>);
        }
    }
    print "\n";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::perlhl - application class for syntax highlighting Perl source code

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use App::perlhl;
    App::perlhl->new({})->run({}, \@ARGV);

=head1 DESCRIPTION

B<App::perlhl> is the application class backing L<perlhl>.

=head1 METHODS

=head2 new

This instantiates a new App::perlhl object. It takes a hashref
of options:

=over 4

=item * html

If true, the output will be an HTML fragment suitable for publishing as part
of a web page. B<NOTE:> In the future, this might output a whole valid document.

=back

The default is to output ANSI colour codes suitable for printing to any
reasonable shell or terminal (which probably means you have the one that'll
break -- well it works on mine, so neener neener).

=head2 run

Unsurprisingly, this runs the application. The method takes a hashref of options,
and an arrayref of filenames to highlight. If there are no filenames, defaults to
C<STDIN>.

=head2 Options

=over 4

=item * version

If present, the application will print version data and exit.

=back

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/App-perlhl/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/App::perlhl/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/App-perlhl>
and may be cloned from L<git://github.com/doherty/App-perlhl.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/App-perlhl/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
