package App::optex::pingu;

my $VERSION = '0.03';

use v5.14;
use warnings;
use utf8;
use Carp;
use open IO => 'utf8', ':std';
use Data::Dumper;

=encoding utf8

=head1 NAME

pingu - optex make-everything-pingu filter

=head1 SYNOPSIS

B<optex> -Mpingu --pingu I<command>

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

=item B<--pingu>

Make command pingu.

=item B<--pingu-image>=I<file>

Set image file.  File is searched at current directory and module
directory.  Standard B<pingu> image is stored as B<pingu.asc>.  If
string C<pingu> is specified, module search the file in the following
order.

    ./pingu
    ./pingu.asc
    module-dir/pingu
    module-dir/pingu.asc

=item B<--pingu-char>

Specify replacement character.  Default is Unicode C<FULL BLOCK>
(U+2588: █).

=item B<--pingu-interval>=I<sec>

Set interval time between printing each lines.  Default is zero.

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

Copyright 2022 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use File::Share qw(dist_dir);
use List::Util qw(first);
use Getopt::EX::Colormap qw(colorize);
use Time::HiRes qw(usleep);

my $image_dir = $ENV{OPTEX_PINGU_IMAGEDIR} //= dist_dir 'App-optex-pingu';

our %param = (
    char => '█',
    repeat => 1,
    interval => 0,
    );

my %reader = (
    asc => \&read_asc,
    );

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
	colorize($+{col}, $param{char} x length($+{str}))
    }xgie;
    /.+/g;
}

sub pingu {
    @_ = map { utf8::is_utf8($_) ? $_ : decode('utf8', $_) } @_;
    my %opt = @_;
    my $name = $opt{name} || 'pingu';
    my @image = get_image($name);
    my $i = 0;
    my $sleep = $param{interval} > 0 ? $param{interval} * 1000000 : 0;
    while (<>) {
	print $image[$i++ % @image], $_;
	usleep $sleep if $sleep > 0;
    }
}

sub set {
    while (my($k, $v) = splice(@_, 0, 2)) {
	exists $param{$k} or next;
	$param{$k} = $v;
    }
    ();
}

1;

__DATA__

mode function

option --pingu-char &set(char=$<shift>)

option --pingu-interval &set(interval=$<shift>)

option --pingu-image -Mutil::filter --osub __PACKAGE__::pingu(name=$<shift>)

option --pingu --pingu-image pingu

option --pingu-original --pingu-char '#' --pingu

#  LocalWords:  pingu optex asc Unicode Cyan cpanminus cpanm rc
#  LocalWords:  localhost Kazumasa Utashiro
