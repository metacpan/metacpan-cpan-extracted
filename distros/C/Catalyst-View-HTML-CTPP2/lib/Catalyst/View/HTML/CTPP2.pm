package Catalyst::View::HTML::CTPP2;

use strict;

use MRO::Compat;

use HTML::CTPP2;
use File::Spec 'tmpdir';

use base 'Catalyst::View';

our $VERSION = '0.02';

my %ctpp2_allow_params = map { $_, 1 }
  qw/arg_stack_size code_stack_size steps_limit max_functions source_charset destination_charset/;


=head1 NAME

Catalyst::View::HTML::CTPP2 - HTML::CTPP2 View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view HTML::CTPP2 HTML::CTPP2

    # lib/MyApp/View/HTML/CTPP2.pm
    package MyApp::View::HTML::CTPP2;

    use base 'Catalyst::View::HTML::CTPP2';

    __PACKAGE__->config(
        INCLUDE_PATH => [
            MyApp->path_to( 'root', 'src' ),
            MyApp->path_to( 'root', 'lib' )
        ),
        TEMPLATE_EXTENSION => '.ctpp2c',

        file_cache      => 1,
        file_cache_time => 24*60*60,
        file_cache_dir  => '/tmp/myapp_cache',

        arg_stack_size      => 1024,
           .....
        source_charset      => 'CP1251',
        destination_charset => 'utf-8'

    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::HTML::CTPP2');

=head1 DESCRIPTION

This is the C<HTML::CTPP2> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item new

Internally used by C<Catalyst>. Used to configure some internal stuff.

=cut

sub new {
    my ($class, $c, $args) = @_;

    my $config = {
        TEMPLATE_EXTENSION => '.ctpp2',
        %{$class->config},
        %{$args}
    };

    if (!(ref $config->{INCLUDE_PATH} eq 'ARRAY')) {
        my $delim = $config->{DELIMITER};
        my @include_path = _coerce_paths($config->{INCLUDE_PATH}, $delim);

        if (!@include_path) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir($root, 'base');
            @include_path = ("$root", "$base");
        }

        $config->{INCLUDE_PATH} = \@include_path;
    }


    if (!exists $config->{file_cache} || $config->{file_cache} != 0) {
        if (   (exists $config->{file_cache_time} && $config->{file_cache_time} > 0)
            || exists $config->{file_cache_dir}
            || (!exists $config->{file_cache_time} && !exists $config->{file_cache_dir}))
        {
            $config->{file_cache_time} ||= 60 * 60;
            $config->{file_cache_dir}  ||= Path::Class::dir(File::Spec->tmpdir, $c->config->{name});
        }
    }

    for (keys %{$config}) {
        $config->{ctpp2_init_args}{$_} = delete $config->{$_} if exists $ctpp2_allow_params{$_};
    }

    my $self = $class->next::method($c, {%$config});

    $self->config($config);

    $self->{ctpp2_obj} = $self->_init_ctpp2($config->{ctpp2_init_args});

    return $self;
}

=item process

Renders the template specified in C<< $c->stash->{template} >> or C<<
$c->request->match >>.
Template params are set up from the contents of C<< $c->stash >>,
augmented with C<base> set to C<< $c->req->base >> and C<name> to 
C<< $c->config->{name} >>. Output is stored in C<< $c->response->body >>.

=cut

sub process {
    my ($self, $c) = @_;

    my $template = $c->stash->{template} || $c->req->match . $self->config->{TEMPLATE_EXTENSION};

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output = $self->render($c, $template);

    unless ($c->response->headers->content_type) {
        $c->response->headers->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

=item render

Renders the given template and returns output. Template params are set up
either from the contents of  C<%$args> if $args is a hashref, or C<< $c->stash >>,
augmented with C<base> set to C<< $c->req->base >> and C<name> to
C<< $c->config->{name} >>.

=cut

sub render {
    my ($self, $c, $filename, $args) = @_;

    $c->log->debug(qq/Rendering template "$filename"/) if $c->debug;

    my $ctpp2_obj = $self->{ctpp2_obj};
    $ctpp2_obj->include_dirs($self->{INCLUDE_PATH});

    my $bytecode = $self->_get_bytecode($filename);

    my $template_params = $args && ref($args) eq 'HASH' ? $args : $c->stash;

    $ctpp2_obj->param(
        {   base => $c->req->base,
            name => $c->config->{name},
            %$template_params
        }
    );

    $c->log->debug("Dumping template parameters:\n" . $ctpp2_obj->dump_params) if $c->debug;

    my $ctpp2_error = $ctpp2_obj->get_last_error();

    if ($ctpp2_error->{error_code}) {
        my $error = sprintf(
            "CTPP2-error: %s\nLine: %s\nPosition: %s\n",
            $ctpp2_error->{error_str},
            $ctpp2_error->{line}, $ctpp2_error->{pos}
        );

        $self->{ctpp2_obj} = $self->_init_ctpp2($self->{ctpp2_init_args});
        $c->error($error);
    }

    my $output;

    eval { $output = $ctpp2_obj->output($bytecode) };

    if (my $error = $@) {
        chomp $error;
        $error = qq/Couldn't render template "$filename". Error: "$error"/;

        $c->log->error($error);
        $c->error($error);
    }

    $ctpp2_obj->clear_params();

    return @{$c->error} ? 0 : $output;
}

=item config

This allows your view subclass to pass additional settings to the
HTML::CTPP2 config-hash.

=back

=cut

=head1 Template Configuration

=head2 PATH CONFIGURATION AND TEMPLATE EXTENSION

=head3 INCLUDE_PATH

The C<INCLUDE_PATH> is used to specify one or more directories in which
template files are located.  When a template is requested that isn't
defined locally as a C<BLOCK>, each of the C<INCLUDE_PATH> directories is
searched in turn to locate the template file.  Multiple directories
can be specified as a reference to a list or as a single string where
each directory is delimited by 'C<:>'.

    __PACKAGE__->config(
        INCLUDE_PATH => MyApp->path_to('root', 'src')
    );

    __PACKAGE__->config(
        INCLUDE_PATH => '/myapp/path1:/myapp/path2:path3'
    );

    __PACKAGE__->config(
        INCLUDE_PATH => [
            MyApp->path_to('root', 'src'),
            MyApp->path_to('root', 'lib')
        ]
    );

On Win32 systems, a little extra magic is invoked, ignoring delimiters
that have 'C<:>' followed by a 'C</>' or 'C<\>'.  This avoids confusion when using
directory names like 'C<C:\Blah Blah>'.


=head3 DELIMITER

Used to provide an alternative delimiter character sequence for 
separating paths specified in the C<INCLUDE_PATH>.  The default
value for C<DELIMITER> is 'C<:>'.

    __PACKAGE__->config(
        DELIMITER    => '; ',
        INCLUDE_PATH => '/myapp/path1;/myapp/path2;path3'
    );

On Win32 systems, the default delimiter is a little more intelligent,
splitting paths only on 'C<:>' characters that aren't followed by a 'C</>'.
This means that the following should work as planned, splitting the 
C<INCLUDE_PATH> into 2 separate directories, C<C:/foo> and C<C:/bar>.

    # on Win32 only
    __PACKAGE__->config(
        INCLUDE_PATH => 'C:/Foo:C:/Bar'
    );

However, if you're using Win32 then it's recommended that you
explicitly set the C<DELIMITER> character to something else (e.g. 'C<;>')
rather than rely on this subtle magic.


=head3 TEMPLATE_EXTENSION

If C<TEMPLATE_EXTENSION> is defined then use template files with the
C<TEMPLATE_EXTENSION> extension will be loaded. Default extension - 'C<.ctpp2>'

    __PACKAGE__->config(
        TEMPLATE_EXTENSION => '.myext'
    );


=head2 CACHING

If any of parameters C<file_cache> ( and > 0 ), C<file_cache_time>, C<file_cache_dir>
is defined - cache will be used. Default value - caching is off.

=head3 file_cache

Set use caching or not. Integer (default - C<0 [caching off]>).

    #caching is on
    __PACKAGE__->config(
        file_cache      => 1,
        file_cache_time => 24*60*60,
        file_cache_dir  => '/tmp/myapp_cache'
    );

    #caching is off
    __PACKAGE__->config(
        file_cache      => 0,
        file_cache_time => 24*60*60

    );


=head3 file_cache_time

This value can be set to control how many long the 
template cached before checking to see if the source template has
changed. Default cache time - C<1 hour>.

    #set cache time 1 day
    __PACKAGE__->config(
        file_cache_time => 24*60*60
    );


=head3 file_cache_dir

The C<file_cache_dir> option is used to specify an alternate directory which compiled
template files should be saved.

    #set cache directory
    #is '/tmp/catalysts/myapp'

    __PACKAGE__->config(
        file_cache_dir  => '/tmp/catalysts/myapp'
    );


=head2 CTPP2-Params

See here - L<HTML::CTPP2>

=cut

sub _init_ctpp2 {
    my ($self, $args) = @_;

    return HTML::CTPP2->new(%{$args});
}

sub _coerce_paths {
    my ($paths, $dlim) = shift;

    return () if (!$paths);
    return @{$paths} if (ref $paths eq 'ARRAY');

    $dlim = ($^O eq 'MSWin32') ? ':(?!\\/)' : ':' unless (defined $dlim);

    return split(/$dlim/, $paths);
}

sub _get_bytecode {
    my ($self, $filename) = @_;

    my $filename_cmpl = Path::Class::file($self->{file_cache_dir}, $filename . 'c');

    if (exists $self->{file_cache_dir}) {
        my $time_now   = time;
        my $file_mtime = (lstat $filename_cmpl)[9];

        my $bytecode;

        if (-e $filename_cmpl && ($time_now - $file_mtime < $self->{file_cache_time})) {
            $bytecode = $self->{ctpp2_obj}->load_bytecode($filename_cmpl);
        }
        else {
            my $filename_cmpl_path = Path::Class::file($filename_cmpl)->dir;

            eval { $filename_cmpl_path->mkpath } if (!-e $filename_cmpl_path);

            $bytecode = $self->{ctpp2_obj}->parse_template($filename);
            $bytecode->save($filename_cmpl);
        }
        return $bytecode;
    }
    else {
        return $self->{ctpp2_obj}->parse_template($filename);
    }
}

=head1 SEE ALSO

L<HTML::CTPP2>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Victor M Elfimov (victor@sols.ru)

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

