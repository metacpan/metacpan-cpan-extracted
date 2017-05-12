package App::ZofCMS::Plugin::FileToTemplate;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use Data::Transformer;
use File::Spec;

sub new { bless {}, shift }

my $Template_Dir;

sub process {
    my ( $self, $template, $query, $config ) = @_;

    $Template_Dir = $config->conf->{templates};

    my $t = Data::Transformer->new( normal => \&callback );
    $t->traverse( $template );
}

sub callback {
    my $in = shift;

    while ( my ( $t  ) = $$in =~ /<FTTR:([^>]+)>/ ) {
        my $tag_result;
        my $file = File::Spec->catfile( $Template_Dir, $t );
        if ( open my $fh, '<', $file ) {
            $tag_result = do { local $/; <$fh>; };
        }
        else {
            $tag_result = $!;
        }
        $$in =~ s/<FTTR:[^>]+>/$tag_result/;
    }

    if ( my ( $t  ) = $$in =~ /<FTTD:([^>]+)>/ ) {
        my $tag_result;
        my $file = File::Spec->catfile( $Template_Dir, $t );

        $tag_result = do $file
            or $tag_result = "ERROR: $! $@";

        $$in = $tag_result;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FileToTemplate - read or do() files into ZofCMS Templates

=head1 SYNOPSIS

In your ZofCMS Template:

    plugins => [ qw/FileToTemplate/ ],
    t  => {
        foo => '<FTTR:index.tmpl>',
    },

In you L<HTML::Template> template:

    <tmpl_var escape='html' name='foo'>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>; it provides functionality to either read (slurp)
or C<do()> files and stick them in place of "tags".. read on to understand more.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 ADDING THE PLUGIN

    plugins => [ qw/FileToTemplate/ ],

Unlike many other plugins to run this plugin you barely need to include it in the list of
plugins to execute.

=head1 TAGS

    t  => {
        foo => '<FTTR:index.tmpl>',
        bar => '<FTTD:index.tmpl>',
    },

Anywhere in your ZofCMS template you can use two "tags" that this plugin provides. Those
"tags" will be replaced - depending on the type of tag - with either the contents of the file
or the last value returned by the file.

Both tags are in format: opening angle bracket, name of the tag in capital letters, semicolon,
filename, closing angle bracket. The filename is relative to your "templates" directory, i.e.
the directory referenced by C<templates> key in Main Config file.

=head2 C<< <FTTR:filename> >>

    t  => {
        foo => '<FTTR:index.tmpl>',
    },

The C<< <FTTR:filename> >> reads (slurps) the contents of the file and tag is replaced
with those contents. You can have several of these tags as values. Be careful reading in
large files with this tag. Mnemonic: B<F>ile B<T>o B<T>emplate B<R>ead.

=head2 C<< <FTTD:filename> >>

    t => {
        foo => '<FTTD:index.tmpl>',
    },

The C<< <FTTD:filename> >> tag will C<do()> your file and the last returned value will be
assigned to the B<value in which the tag appears>, in other words, having
C<< foo => '<FTTD:index.tmpl>', >> and C<< foo => '<FTTD:index.tmpl> blah blah blah', >>
is the same. Using this tag, for example, you can add large hashrefs or config hashrefs
into your templates without clobbering them. Note that if the C<do()> cannot find your file
or compilation of the file fails, the value with the tag will be replaced by the error message.
Mnemomic: B<F>ile B<T>o B<T>emplate B<D>o.

=head1 NON-CORE PREREQUISITES

The plugin requires one non-core module: L<Data::Transformer>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut