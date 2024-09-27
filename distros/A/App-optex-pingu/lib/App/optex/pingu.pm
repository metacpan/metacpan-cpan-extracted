package App::optex::pingu;

my $VERSION = '1.00';

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

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu2-light.png">

=end html

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu2-dark.png">

=end html

This module is a quite good example to demonstrate L<optex(1)> command
features.

=head1 OPTION

=over 7

=item B<-->[B<no->]B<pingu>

Produce images.  Enabled by default.

=item B<--image>=I<file>

Set image file.  File is searched at current directory and module
directory.  Standard B<pingu> image is stored as F<pingu.asc2>.  If
string C<pingu> is specified, module search the file in the following
order.

    ./pingu
    ./pingu.asc2
    ./pingu.asc
    module-dir/pingu
    module-dir/pingu.asc2
    module-dir/pingu.asc

=begin comment

=item B<--char>=I<c>

Specify replacement character.  Default is Unicode C<FULL BLOCK>
(U+2588: █).

=end comment

=item B<--interval>=I<sec>

Specifies the interval time in seconds between outputting each line.
Default is 0.1 seconds.

=back

=head1 IMAGE FILE FORMAT

=over 4

=item ASCII (C<.asc>)

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

C<pingu.asc>:

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

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu-light.png">

=end html

=begin html

<p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/optex-pingu/refs/heads/main/images/pingu-dark.png">

=end html

=item ASCII2 (C<.asc2>)

Each pixel is represented by two blocks, one in the upper half and one
in the lower half, with each color represented by two lines of data.

C<pingu.asc2>:

     ...        .     ...   ..    ..     .........           
     ...        .     ...   ..    ..     .........           
     ...     ....          ..  ..      ... .....  .. ..      
     ...     ....          ..  ..      ... .....  .. ..      
     ...    .......      ...         ... . .....  kkkkk      
     ...    .......      kkkkkkk     ... . ..... kkkkkkk     
    .....  ........ . kkkkkkkkkkkkk .....  ...  kkkkkkkkk.  .
    .....  ........ kkkkkkkkkkkkkkkkk....  ... kkkkkkkkkk.  .
     .... ........ kkkkkkkkkkkkkkkkkkk .  ... kkkkkkkkkkkk   
     .... ........kkkkkkkkkkkkkkkkkkkkk.  ... kkkkkkkkkkkk   
          ....... kkkwwkkkkkkkkkkkkkkkkk.... kkkkkkkkkkkkk   
          .......kkkwwwwkkkkkkkkkkkkkkkk.... kkkkkkkkkkkk    
    .    .  .... kkwwKKwwkkkkkkkkkkkwwkkk...kkkkkkkkkkkkk    
    .    .  ....kkkwwKKwwkkkkkkkkkkwwwwkk...kkkkkkkkkkkkk    
       ..   ....kkkkwwwwkkkkkkkkkkwwKKwwkk. .kkkkkkkkkkkk    
       ..   ....kkkkkwwkkkkrrrrkkkwwKKwwkk. .kkkkkkkkkkk     
        .       kkkkkkkkkrrrrrrrrkkwwwwkkk   .kkkkkkkkkk     
        .        kkkkkkkrrrrrrrrrrkkwwkkkk   . kkkkkkkkk     
       ....     .kkkkkkkrrrrrrrrrrkkkkkkk.      kkkkkkkk     
       ....     . kkkkkkkrrrrrrrrkkkkkkkk.      kkkkkkkk     
      .....      . kkkkkkkkrrrrkkkkkkkkk.        kkkkkkk.    
      .....      .  kkkkkkkkkkkkkkkkkkkk.        kkkkkkk.    
    ......     .. .  kkkkkkkkkkkkkkkkkk. .      .kkkkkkk     
    ......     .. . kkkkkkkkkkkkkkkkk  . .      .kkkkkk      
    ......        kkkkkkkkkkkkkkkkkkkk  .      .kkkkkkk      
    ......      kkkkkkkkkkkkkkkkkkkkkkk .      .kkkkkkk      
    ......   . kkkkkkkkkkkkkkkkkyyykkkkk   ..  kkkkkkk       
    ......   .kkkkkkkkkkkkkkkkyyyWWWWkkkk  .. kkkkkkkk       
    ...    . kkkkkkkkkkkkkkkkyyWWWWWWWkkkkk  kkkkkkkk.       
    ...    .kkkkkkkkkkkkkkkkyyWWWWWWWWWkkkkkkkkkkkkk .       
           kkkkkkkkkkkkkkkkyyWWWWWWWWWWWkkkkkkkkkk .         
           kkkkkkkkkkkkkkkyyWWWWWWWWWWWWWkkkkkkkk  .         
          kkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWkkkkk .            
         kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWkk   .            
         kkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWWW   ........       
        kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWWW  ........       
      .kkkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWWWWW    .........    
      .kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWWWWW   .........    
     .kkkkkkkkkkkkkkkkyyWWWWWWWWWWWWWWWWWWWWW       .... . . 
     .kkkkkkkkkkkkkkkkyWWWWWWWWWWWWWWWWWWWWWW       .... . . 


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
        pingu = "ping -Mpingu"

=head1 MAKING NEW PING OPTION

You can add, say, B<--pingu> option to the original L<ping(1)>
command.  Make a symbolic link C<< ping->optex >> in F<~/.optex.d/bin>
directory:

    $ optex --ln ping

And create an rc file F<~/.optex.d/ping.rc> for B<ping>:

    option --pingu -Mpingu

Then pingu will show up when you use B<--pingu> option to execute
L<ping(1)> command:

    $ ping --pingu localhost -c15

If you want to enable this option always (really?), put next line in
your F<~/.optex.d/ping.rc>:

    option default --pingu

=head1 SEE ALSO

L<https://github.com/sheepla/pingu>

L<App::optex>,
L<https://github.com/kaz-utashiro/optex/>

L<App::optex::pingu>,
L<https://github.com/kaz-utashiro/optex-pingu/>

=head2 ARTICLES

L<https://qiita.com/kaz-utashiro/items/abb436d7df349fe84e69>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2022-2024 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use File::Share qw(dist_dir);
use List::Util qw(first pairmap);
use Getopt::EX::Colormap qw(colorize);
use Time::HiRes qw(usleep);
use Scalar::Util;
use Hash::Util qw(lock_keys);
*is_number = \&Scalar::Util::looks_like_number;

use App::optex::pingu::Picture;

my $image_dir = $ENV{OPTEX_PINGU_IMAGEDIR} //= dist_dir 'App-optex-pingu';

our %opt = (
    pingu    => \(our $pingu = 1),
    image    => 'pingu',
    char     => '█',
    repeat   => 1,
    interval => 0.1,
    );
lock_keys %opt;

sub hash_to_spec {
    pairmap {
	my $ref = ref $b;
	if    (not defined $b)   { "$a!"  }
	elsif ($ref eq 'SCALAR') { "$a!"  }
	elsif (is_number($b))    { "$a=f" }
	else                     { "$a=s" }
    } shift->%*;
}

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
	    map { "${dir}${name}$_" } '', '.asc2', '.asc';
	} '', "$image_dir/";
    };
    die "$name: image file not found.\n" unless $file;
    App::optex::pingu::Picture::load($file);
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
	exists $opt{$k} or die "$k: invaid paraeter.\n";
	$opt{$k} = $v;
    }
    ();
}

1;

__DATA__

# define --pingu for backward compatibility
option --pingu $<ignore>

#  LocalWords:  pingu optex asc Unicode Cyan cpanminus cpanm rc
#  LocalWords:  localhost Kazumasa Utashiro
