package App::optex::pingu;

my $VERSION = '0.99';

use v5.24;
use warnings;
use utf8;
use Carp;
use open IO => 'utf8', ':std';
use Data::Dumper;

=encoding utf8

=head1 NAME

pingu - optex make-everything-pingu filter

=head1 SYNOPSIS

B<optex> -Mpingu [ options -- ] I<command>

=head1 DESCRIPTION

This B<optex> module is greatly inspired by L<pingu(1)> command and
make every command pingu not only L<ping(1)>.  As for original
command, see L</SEE ALSO> section.  All honor for this idea should go
to the original author.

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/main/images/pingu-black.png">

=end html

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/main/images/pingu-white.png">

=end html

This module is a quite good example to demonstrate L<optex(1)> command
features.

=head1 OPTION

=over 7

=item B<-->[B<no->]B<pingu>

Produce images.  Enabled by default.

=item B<--image>=I<file>

Set image file.  File is searched at current directory and module
directory.  Standard B<pingu> image is stored as B<pingu.asc>.  If
string C<pingu> is specified, module search the file in the following
order.

    ./pingu
    ./pingu.asc
    module-dir/pingu
    module-dir/pingu.asc

=item B<--char>=I<c>

Specify replacement character.  Default is Unicode C<FULL BLOCK>
(U+2588: █).

=item B<--interval>=I<sec>

Specifies the interval time in seconds between outputting each line.
Default is 0.1 seconds.

=back

=head1 IMAGE FILE FORMAT

=over 4

=item ASCII

Each [C<RGBCMYWKrgbcmywk>] character is converted to specified letter
with color which the character itself describe.  Upper-case character
represent normal ANSI color and lower-case means high-intensity color.

    R  r  Red
    G  g  Green
    B  b  Blue
    C  c  Cyan
    M  m  Magenta
    Y  y  Yellow
    K  k  Black
    W  w  White

Line start with C<#> is treated as a comment.

Default pingu image:

     ...        .     ...   ..    ..     .........           
     ...     ....          ..  ..      ... .....  .. ..      
     ...    .......      ...         ... . ..... kkkkkkk     
    .....  ........ .kkkkkkkkkkkkkkk.....  ... kkkkkkkkkk.  .
     .... ........kkkkkkkkkkkkkkkkkkkkk.  ... kkkkkkkkkkk    
          ....... kkwwwwkkkkkkkkkkkkkkkk.... kkkkkkkkkkkk    
    .    .  .... kkwwkkwwkkkkkkkkkkwwwwkk... kkkkkkkkkkk     
       ..   ....kkkkwwwwkkrrrrrrkkwwkkwwk.. .kkkkkkkkkkk     
        .       kkkkkkkkrrrrrrrrrrkwwwwkk.   .kkkkkkkkkk     
       ....     .kkkkkkkkrrrrrrrrkkkkkkkk.      kkkkkkkk     
      .....      .  kkkkkkkkkkkkkkkkkkkk.        kkkkkkk.    
    ......     .. . kkkkkkkkkkkkkkkkkk . .      .kkkkkkk     
    ......       kkkkkkkkkkkkkkkkkkkkk  .      .kkkkkkk      
    ......   .kkkkkkkkkkkkkkkkkkyywwkkkkk  ..  kkkkkkk       
    ...    . kkkkkkkkkkkkkkkkywwwwwwwwwkkkkkkkkkkkkkk.       
           kkkkkkkkkkkkkkkkywwwwwwwwwwwwwkkkkkkkkk .         
          kkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwkk    .            
         kkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwwww  ........       
      .kkkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwwwww    .........    
     .kkkkkkkkkkkkkkkkywwwwwwwwwwwwwwwwwwwwww       .... . . 

=back

Other file format is not supported yet.

Coloring is done by L<Getopt::EX::Colormap> module.  See its document
for detail.

=head1 INSTALL

Use L<cpanminus(1)> command:

    cpanm App::optex::pingu

=head1 PINGU ALIAS

You can set shell alias B<pingu> to call L<ping(1)> command through
B<optex>.

    alias pingu='optex -Mpingu --pingu ping'

However, there is more sophisticated way to use B<optex> alias
function.  Next command will make symbolic link C<< pingu->optex >> in
F<~/.optex.d/bin> directory:

    $ optex --ln pingu

Executing this symbolic link, optex will call system installed
B<pingu> command.  So make an alias in F<~/.optex.d/config.toml> to
call L<ping(1)> command instead:

    [alias]
        pingu = "ping -Mpingu --pingu"

=head1 MAKING NEW PING OPTION

You can add, say, B<--with-pingu> option to the original L<ping(1)>
command.  Make a symbolic link C<< ping->optex >> in F<~/.optex.d/bin>
directory:

    $ optex --ln ping

And create an rc file F<~/.optex.d/ping.rc> for B<ping>:

    option --with-pingu -Mpingu --pingu

Then pingu will show up when you use B<--with-pingu> option to execute
L<ping(1)> command:

    $ ping --with-pingu localhost -c15

If you want to enable this option always (really?), put next line in
your F<~/.optex.d/ping.rc>:

    option default --with-pingu

=head1 SEE ALSO

L<https://github.com/sheepla/pingu>

L<App::optex>,
L<https://github.com/kaz-utashiro/optex/>

L<App::optex::pingu>,
L<https://github.com/kaz-utashiro/optex-pingu/>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022-2024 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use File::Share qw(dist_dir);
use List::Util qw(first pairmap);
use Getopt::EX::Colormap qw(colorize);
use Time::HiRes qw(usleep);
use Scalar::Util;
*is_number = \&Scalar::Util::looks_like_number;

my $image_dir = $ENV{OPTEX_PINGU_IMAGEDIR} //= dist_dir 'App-optex-pingu';

our %opt = (
    pingu    => \(our $pingu = 1),
    image    => 'pingu',
    char     => '█',
    repeat   => 1,
    interval => 0.1,
    );

sub hash_to_spec {
    pairmap {
	my $ref = ref $b;
	if    (not defined $b)   { "$a!"  }
	elsif ($ref eq 'SCALAR') { "$a!"  }
	elsif (is_number($b))    { "$a=f" }
	else                     { "$a=s" }
    } shift->%*;
}

my %reader = (
    asc => \&read_asc,
    );

use App::optex::util::filter qw(io_filter);

sub finalize {
    our($mod, $argv) = @_;
    #
    # private option handling
    #
    if (@$argv and $argv->[0] !~ /^-M/ and
	defined(my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	splice @$argv, $i, 1; # remove '--'
	if (local @ARGV = splice @$argv, 0, $i) {
	    use Getopt::Long qw(GetOptionsFromArray);
	    Getopt::Long::Configure qw(bundling);
	    GetOptions \%opt, hash_to_spec \%opt or die "Option parse error.\n";
	}
    }
    io_filter(\&pingu, STDOUT => 1);
}

sub get_image {
    my $name = shift;
    my $file = do {
	first { -s }
	map {
	    my $dir = $_;
	    map { "${dir}${name}$_" } '', '.asc';
	} '', "$image_dir/";
    };
    die "$name: image file not found.\n" unless $file;
    my $type = ($file =~ /\.(\w+$)/)[0] || 'asc';
    my $reader = $reader{$type} // $reader{'asc'};
    $reader->($file);
}

sub read_asc {
    my $file = shift;
    open my $fh, '<', $file or die "$file: $!\n";
    local $_ = do { local $/; <$fh> };
    s/^#.*\n//mg;
    s{ (?<str>(?<col>[RGBCMYWK])\g{col}*) }{
	colorize($+{col}, $opt{char} x length($+{str}))
    }xgie;
    /.+/g;
}

sub pingu {
    @_ = map { utf8::is_utf8($_) ? $_ : decode('utf8', $_) } @_;
    my %param = @_;
    my @image = get_image($opt{image});
    my $i = 0;
    my $sleep = $opt{interval} > 0 ? $opt{interval} * 1000000 : 0;
    while (<>) {
	print $image[$i++ % @image] if $pingu;
	print $_;
	usleep $sleep if $sleep > 0;
    }
}

sub set {
    while (my($k, $v) = splice(@_, 0, 2)) {
	exists $opt{$k} or next;
	$opt{$k} = $v;
    }
    ();
}

1;

__DATA__

#  LocalWords:  pingu optex asc Unicode Cyan cpanminus cpanm rc
#  LocalWords:  localhost Kazumasa Utashiro
