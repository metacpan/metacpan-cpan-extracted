package Daizu::TTProvider;
use warnings;
use strict;

use base 'Template::Provider';

use Carp::Assert qw( assert DEBUG );
use Path::Class qw( file );
use Daizu::Util qw(
    db_row_id
    wc_file_data
);

=head1 NAME

Daizu::TTProvider - fetch TT templates from a Daizu working copy

=head1 DESCRIPTION

This is a subclass of L<Template::Provider> which overrides the normal
way in which templates are loaded.  It loads templates from the database,
and searches for them in directories determined by the path of the file
being published.  So for example, there can be templates in various
I<_template> directories at various points in the working copy file hierarchy,
so each website can have its own set of templates which override the default
ones, and subsections can have extra templates, and so on.

This module is used in the
L<generate_web_page method in Daizu::Gen|Daizu::Gen/$gen-E<gt>generate_web_page($file, $url, $template_overrides, $template_vars)>.

If a template can't be found in the working copy I<_template> directories,
then it is looked for among the templates distributed with Daizu.  Thus these
templates provide a default site look-and-feel, while they can be
overridden by adding templates to the repository.

TODO - currently there is a kludge to allow templates whose names are
overridden by a generator to include the original version.  They can
do this by prefixing the name with C<no-override:>, but this feature
is likely to be removed and replaced with something better, once I've
figure out what that is.

While testing templates it may be easier to edit them as normal files and
have this module instead load those, so that you don't have to do a commit
and a working copy update after every experimental change.  To make this
happen, add something like the following to your Daizu CMS configuration
file:

=for syntax-highlight xml

    <template-test path="/home/geoff/svn/web_geoff" />

=head1 USING FROM CODE

This example shows how to do Template Toolkit processing with templates
loaded from a Daizu working copy.  It is intended to generate the file
in C<$file> using template C<$template_name>.  This example is derived
from code in L<Daizu::Gen>.

=for syntax-highlight perl

    use Daizu::TTProvider;

    my $provider = Daizu::TTProvider->new({
        daizu_cms => $cms,
        daizu_wc_id => $file->{wc_id},
        daizu_file_path => $file->directory_path,
        daizu_template_overrides => $template_overrides,
    });

    my $tt = Template->new({
        LOAD_TEMPLATES => $provider,
    }) or die $Template::ERROR;

    $tt->process($template_name, \%vars, $fh)
        or die $Template::ERROR;

The option C<daizu_template_overrides> can be undef or a reference to
a hash of rewriting instructions.  Each key is the name of a template,
including its relative path.  If that template is loaded, this module
will in fact load the template specified in the corresponding value.
This mechanism is used by subclasses of L<Daizu::Gen> to customize
presentation without the user having to put override templates in their
repository.  In effect, it provides an additional way of overriding
which templates are used, which is orthogonal to the I<_template>
directories in working copies.

=head1 METHODS

=over

=cut

sub _init
{
    my ($self, $args) = @_;

    $self->{$_} = $args->{$_} for keys %$args;
    $self->{daizu_wc_id} ||= $self->{daizu_cms}->{live_wc_id};

    return $self->SUPER::_init();
}

=item $provider-E<gt>fetch($name)

Return a list of two values: the data for the named template and an error
code.  The second value will be true if there was an error.

=cut

sub fetch
{
    my ($self, $name) = @_;

    # We don't do refs or file handles.
    return (undef, Template::Constants::STATUS_DECLINED)
        if ref $name;

    my ($data, $error) = $self->_load($name);
    ($data, $error) = $self->_compile($data)
        unless $error;
    $data = $self->_store($name, $data)
        unless $error;

    return ($data, $error);
}

sub _load
{
    my ($self, $name) = @_;

    my $cms = $self->{daizu_cms};
    my $db = $cms->{db};
    my $test_path = $cms->{template_test_path};

    unless ($name =~ s/^no-override://) {
        my $template_overrides = $self->{daizu_template_overrides};
        $name = $template_overrides->{$name}
            if exists $template_overrides->{$name};
    }

    my $path = $self->{daizu_file_path};
    my $text;
    while (1) {
        my $tmpl_dir = $path eq '' ? '_template' : "$path/_template";

        if (defined $test_path) {
            my $tmpl_filename = file($test_path, $tmpl_dir, $name);
            if (-f $tmpl_filename) {
                open my $fh, '<', $tmpl_filename
                    or die "error opening template file '$tmpl_filename': $!";
                binmode $fh;
                $text = \do { local $/; <$fh> };
                last;
            }
        }
        else {
            my $tmpl_id = db_row_id($db, 'wc_file',
                wc_id => $self->{daizu_wc_id},
                path => "$tmpl_dir/$name",
            );

            $text = wc_file_data($db, $tmpl_id), last
                if defined $tmpl_id;
        }

        # Not found, so use the default template.
        if ($path eq '') {
            my $tmpl_filename = file($cms->{template_default_path}, $name);
            if (-f $tmpl_filename) {
                open my $fh, '<', $tmpl_filename
                    or die "error opening template file '$tmpl_filename': $!";
                binmode $fh;
                $text = \do { local $/; <$fh> };
                last;
            }

            # Doesn't exist anywhere.
            return (undef, Template::Constants::STATUS_DECLINED);
        }

        $path = $path =~ m!^(.*)/[^/]+\z! ? $1 : '';
    }

    assert(defined $text) if DEBUG;

    my $time = time();
    my $data = {
        time => $time,
        load => $time,
        name => $name,
        text => $$text,
    };

    return ($data, undef);
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab
