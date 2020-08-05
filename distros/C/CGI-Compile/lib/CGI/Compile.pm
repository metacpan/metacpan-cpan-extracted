package CGI::Compile;

use strict;
use 5.008_001;

our $VERSION = '0.25';

use Cwd;
use File::Basename;
use File::Spec::Functions;
use File::pushd;
use File::Temp;
use File::Spec;
use File::Path;
use Sub::Name 'subname';

our $RETURN_EXIT_VAL = undef;

sub new {
    my ($class, %opts) = @_;

    $opts{namespace_root} ||= 'CGI::Compile::ROOT';

    bless \%opts, $class;
}

our $USE_REAL_EXIT;
BEGIN {
    $USE_REAL_EXIT = 1;

    my $orig = *CORE::GLOBAL::exit{CODE};

    my $proto = $orig ? prototype $orig : prototype 'CORE::exit';

    $proto = $proto ? "($proto)" : '';

    $orig ||= sub {
        my $exit_code = shift;

        CORE::exit(defined $exit_code ? $exit_code : 0);
    };

    no warnings 'redefine';

    *CORE::GLOBAL::exit = eval qq{
        sub $proto {
            my \$exit_code = shift;

            \$orig->(\$exit_code) if \$USE_REAL_EXIT;

            die [ "EXIT\n", \$exit_code || 0 ]
        };
    };
    die $@ if $@;
}

my %anon;

sub compile {
    my($class, $script, $package) = @_;

    my $self = ref $class ? $class : $class->new;

    my($code, $path, $dir, $subname);

    if (ref $script eq 'SCALAR') {
        $code      = $$script;

        $package ||= (caller)[0];

        $subname   = '__CGI' . $anon{$package}++ . '__';
    } else {
        $code = $self->_read_source($script);

        $path = Cwd::abs_path($script);
        $dir  = File::Basename::dirname($path);

        my $genned_package;

        ($genned_package, $subname) = $self->_build_subname($path || $script);

        $package ||= $genned_package;
    }

    my $warnings = $code =~ /^#!.*\s-w\b/ ? 1 : 0;
    $code =~ s/^__END__\r?\n.*//ms;
    $code =~ s/^__DATA__\r?\n(.*)//ms;
    my $data = defined $1 ? $1 : '';

    # TODO handle nph and command line switches?
    my $eval = join '',
        "package $package;",
        'sub {',
        'local $CGI::Compile::USE_REAL_EXIT = 0;',
        "\nCGI::initialize_globals() if defined &CGI::initialize_globals;",
        'local ($0, $CGI::Compile::_dir, *DATA);',
        '{ my ($data, $path, $dir) = @_[1..3];',
        ($path ? '$0 = $path;' : ''),
        ($dir  ? '$CGI::Compile::_dir = File::pushd::pushd $dir;' : ''),
        q{open DATA, '<', \$data;},
        '}',
        # NOTE: this is a workaround to fix a problem in Perl 5.10
        q(local @SIG{keys %SIG} = do { no warnings 'uninitialized'; @{[]} = values %SIG };),
        "local \$^W = $warnings;",
        'my $rv = eval {',
        'local @ARGV = @{ $_[4] };', # args to @ARGV
        'local @_    = @{ $_[4] };', # args to @_ as well
        ($path ? "\n#line 1 $path\n" : ''),
        $code,
        "\n};",
        q{
        {
            no warnings qw(uninitialized numeric pack);
            my $self     = shift;
            my $exit_val = unpack('C', pack('C', sprintf('%.0f', $rv)));
            if ($@) {
                die $@ unless (
                  ref($@) eq 'ARRAY' and
                  $@->[0] eq "EXIT\n"
                );
                my $exit_param = unpack('C', pack('C', sprintf('%.0f', $@->[1])));

                if ($exit_param != 0 && !$CGI::Compile::RETURN_EXIT_VAL && !$self->{return_exit_val}) {
                    die "exited nonzero: $exit_param";
                }

                $exit_val = $exit_param;
            }

            return $exit_val;
        }
        },
        '};';

    my $sub = do {
        no warnings 'uninitialized'; # for 5.8
        # NOTE: this is a workaround to fix a problem in Perl 5.10
        local @SIG{keys %SIG} = @{[]} = values %SIG;
        local $USE_REAL_EXIT = 0;

        my $code = $self->_eval($eval);
        my $exception = $@;

        die "Could not compile $script: $exception" if $exception;

        subname "${package}::$subname", sub {
            my @args = @_;
            # this is necessary for MSWin32
            my $orig_warn = $SIG{__WARN__} || sub { warn(@_) };
            local $SIG{__WARN__} = sub { $orig_warn->(@_) unless $_[0] =~ /^No such signal/ };
            $code->($self, $data, $path, $dir, \@args)
        };
    };

    return $sub;
}

sub _read_source {
    my($self, $file) = @_;

    open my $fh, "<", $file or die "$file: $!";
    return do { local $/; <$fh> };
}

sub _build_subname {
    my($self, $path) = @_;

    my ($volume, $dirs, $file) = File::Spec::Functions::splitpath($path);
    my @dirs = File::Spec::Functions::splitdir($dirs);

    my $name    = $file;
    my $package = join '_', grep { defined && length } $volume, @dirs, $name;

    # Escape everything into valid perl identifiers
    s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg for $package, $name;

    # make sure the identifiers don't start with a digit
    s/^(\d)/_$1/ for $package, $name;

    $package = $self->{namespace_root} . ($package ? "::$package" : '');

    return ($package, $name);
}

# define tmp_dir value later on first usage, otherwise all children
# share the same directory when forked
my $tmp_dir;
sub _eval {
    my $code = \$_[1];

    # we use a tmpdir chmodded to 0700 so that the tempfiles are secure
    $tmp_dir ||= File::Spec->catfile(File::Spec->tmpdir, "cgi_compile_$$");

    if (! -d $tmp_dir) {
        mkdir $tmp_dir          or die "Could not mkdir $tmp_dir: $!";
        chmod 0700, $tmp_dir    or die "Could not chmod 0700 $tmp_dir: $!";
    }

    my ($fh, $fname) = File::Temp::tempfile('cgi_compile_XXXXX',
        UNLINK => 1, SUFFIX => '.pm', DIR => $tmp_dir);

    print $fh $$code;
    close $fh;

    my $sub = do $fname;

    unlink $fname or die "Could not delete $fname: $!";

    return $sub;
}

END {
    if ($tmp_dir and -d $tmp_dir) {
        File::Path::remove_tree($tmp_dir);
    }
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

CGI::Compile - Compile .cgi scripts to a code reference like ModPerl::Registry

=head1 SYNOPSIS

  use CGI::Compile;
  my $sub = CGI::Compile->compile("/path/to/script.cgi");

=head1 DESCRIPTION

CGI::Compile is a utility to compile CGI scripts into a code
reference that can run many times on its own namespace, as long as the
script is ready to run on a persistent environment.

B<NOTE:> for best results, load L<CGI::Compile> before any modules used by your
CGIs.

=head1 RUN ON PSGI

Combined with L<CGI::Emulate::PSGI>, your CGI script can be turned
into a persistent PSGI application like:

  use CGI::Emulate::PSGI;
  use CGI::Compile;

  my $cgi_script = "/path/to/foo.cgi";
  my $sub = CGI::Compile->compile($cgi_script);
  my $app = CGI::Emulate::PSGI->handler($sub);

  # $app is a PSGI application

=head1 CAVEATS

If your CGI script has a subroutine that references the lexical scope
variable outside the subroutine, you'll see warnings such as:

  Variable "$q" is not available at ...
  Variable "$counter" will not stay shared at ...

This is due to the way this module compiles the whole script into a
big C<sub>. To solve this, you have to update your code to pass around
the lexical variables, or replace C<my> with C<our>. See also
L<http://perl.apache.org/docs/1.0/guide/porting.html#The_First_Mystery>
for more details.

=head1 METHODS

=head2 new

Does not need to be called, you only need to call it if you want to set your
own C<namespace_root> for the generated packages into which the CGIs are
compiled into.

Otherwise you can just call L</compile> as a class method and the object will
be instantiated with a C<namespace_root> of C<CGI::Compile::ROOT>.

You can also set C<return_exit_val>, see L</RETURN CODE> for details.

Example:

    my $compiler = CGI::Compile->new(namespace_root => 'My::CGIs');
    my $cgi      = $compiler->compile('/var/www/cgi-bin/my.cgi');

=head2 compile

Takes either a path to a perl CGI script or a source code and some
other optional parameters and wraps it into a coderef for execution.

Can be called as either a class or instance method, see L</new> above.

Parameters:

=over 4

=item * C<$cgi_script>

Path to perl CGI script file or a scalar reference that contains the
source code of CGI script, required.

=item * C<$package>

Optional, package to install the script into, defaults to the path parts of the
script joined with C<_>, and all special characters converted to C<_%2x>,
prepended with C<CGI::Compile::ROOT::>.

E.g.:

    /var/www/cgi-bin/foo.cgi

becomes:

    CGI::Compile::ROOT::var_www_cgi_2dbin_foo_2ecgi

=back

Returns:

=over 4

=item * C<$coderef>

C<$cgi_script> or C<$$code> compiled to coderef.

=back

=head1 SCRIPT ENVIRONMENT

=head2 ARGUMENTS

Things like the query string and form data should generally be in the
appropriate environment variables that things like L<CGI> expect.

You can also pass arguments to the generated coderef, they will be
locally aliased to C<@_> and C<@ARGV>.

=head2 C<BEGIN> and C<END> blocks

C<BEGIN> blocks are called once when the script is compiled.
C<END> blocks are called when the Perl interpreter is unloaded.

This may cause surprising effects. Suppose, for instance, a script that runs
in a forking web server and is loaded in the parent process. C<END>
blocks will be called once for each worker process and another time
for the parent process while C<BEGIN> blocks are called only by the
parent process.

=head2 C<%SIG>

The C<%SIG> hash is preserved meaning the script can change signal
handlers at will. The next invocation gets a pristine C<%SIG> again.

=head2 C<exit> and exceptions

Calls to C<exit> are intercepted and converted into exceptions. When
the script calls C<exit 19> and exception is thrown and C<$@> contains
a reference pointing to the array

    ["EXIT\n", 19]

Naturally, L<perlvar/$^S> (exceptions being caught) is always C<true>
during script runtime.

If you really want to exit the process call C<CORE::exit> or set
C<$CGI::Compile::USE_REAL_EXIT> to true before calling exit:

    $CGI::Compile::USE_REAL_EXIT = 1;
    exit 19;

Other exceptions are propagated out of the generated coderef. The coderef's
caller is responsible to catch them or the process will exit.

=head2 Return Code

The generated coderef's exit value is either the parameter that was
passed to C<exit> or the value of the last statement of the script. The
return code is converted into an integer.

On a C<0> exit, the coderef will return C<0>.

On an explicit non-zero exit, by default an exception will be thrown of
the form:

    exited nonzero: <n>

where C<n> is the exit value.

This only happens for an actual call to L<perfunc/exit>, not if the last
statement value is non-zero, which will just be returned from the
coderef.

If you would prefer that explicit non-zero exit values are returned,
rather than thrown, pass:

    return_exit_val => 1

in your call to L</new>.

Alternately, you can change this behavior globally by setting:

    $CGI::Compile::RETURN_EXIT_VAL = 1;

=head2 Current Working Directory

If C<< CGI::Compile->compile >> was passed a script file, the script's
directory becomes the current working directory during the runtime of
the script.

NOTE: to be able to switch back to the original directory, the compiled
coderef must establish the current working directory. This operation may
cause an additional flush operation on file handles.

=head2 C<STDIN> and C<STDOUT>

These file handles are not touched by C<CGI::Compile>.

=head2 The C<DATA> file handle

If the script reads from the C<DATA> file handle, it reads the C<__DATA__>
section provided by the script just as a normal script would do. Note,
however, that the file handle is a memory handle. So, C<fileno DATA> will
return C<-1>.

=head2 CGI.pm integration

If the subroutine C<CGI::initialize_globals> is defined at script runtime,
it is called first thing by the compiled coderef.

=head1 PROTECTED METHODS

These methods define some of the internal functionality of
L<CGI::Compile> and may be overloaded if you need to subclass this
module.

=head2 _read_source

Reads the source of a CGI script.

Parameters:

=over 4

=item * C<$file_path>

Path to the file the contents of which is to be read.

=back

Returns:

=over 4

=item * C<$source>

The contents of the file as a scalar string.

=back

=head2 _build_subname

Creates a package name and coderef name into which the CGI coderef will be
compiled into. The package name will be prepended with
C<$self->{namespace_root}>.

Parameters:

=over 4

=item * C<$file_path>

The path to the CGI script file, the package name is generated based on
this path.

=back

Returns:

=over 4

=item * C<$package>

The generated package name.

=back

=over 4

=item * C<$subname>

The generated coderef name, based on the file name (without directory) of the
CGI file path.

=back

=head2 _eval

Takes the generated perl code, which is the contents of the CGI script
and some other things we add to make everything work smoother, and
returns the evaluated coderef.

Currently this is done by writing out the code to a temp file and
reading it in with L<perlfunc/do> so that there are no issues with
lexical context or source filters.

Parameters:

=over 4

=item * C<$code>

The generated code that will make the coderef for the CGI.

=back

Returns:

=over 4

=item * C<$coderef>

The coderef that is the resulting of evaluating the generated perl code.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 CONTRIBUTORS

Rafael Kitover E<lt>rkitover@gmail.comE<gt>

Hans Dieter Pearcey E<lt>hdp@cpan.orgE<gt>

kocoureasy E<lt>igor.bujna@post.czE<gt>

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

Jörn Reder E<lt>jreder@dimedis.deE<gt>

Pavel Mateja E<lt>pavel@verotel.czE<gt>

lestrrat E<lt>lestrrat+github@gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<ModPerl::RegistryCooker> L<CGI::Emulate::PSGI>

=cut
