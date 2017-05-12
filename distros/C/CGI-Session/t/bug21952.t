#    http://rt.cpan.org/Public/Bug/Display.html?id=21952

#    Hello Mark & Sherzod
#
#
#    I just started yesterday to use CGI::Session (as an embedded component 
#    of CGI::Forge ), and would like to report a wrong behavior.
#
#    -----------------------------------------------------
#    My environment :
#
#    CGI::Session : Version 4.14
#    uname -a : Linux perl.smartech.pf 2.6.16.4 #1 PREEMPT Mon Apr 17 
#    15:12:40 TAHT 2006 i686 AMD Athlon(TM) XP 2800+ unknown GNU/Linux
#    perl -v : This is perl, v5.8.7 built for i386-linux
#
#    -----------------------------------------------------
#    My code (summarized) :
#
#    1 my $opt_dsn = ...
#    2 my $cgiquery = ...
#    3 my $s = CGI::Session->load('driver:file;serializer:default', 
#    $cgiquery, $opt_dsn) or die;
#    4 $s = CGI::Session->new('driver:file;serializer:default', $cgiquery, 
#    $opt_dsn) if $s->is_empty();
#    5 <END OF PROG>
#
#    -----------------------------------------------------
#    The suspicious behavior...
#
#    - The statement line 3 leads to the creation of a new CGI::Session 
#    object, say A, and to the creation of a CGI::Session::Sriver::file 
#    driver object, say B.
#
#    - Statement 4 resets $s, so A & B, no longer reachable are DESTROYed and 
#    garbage collected.The destruction of A is caught in CGI/Session.pm to 
#    automagically call CGI::Session::flush() which does nothing in this 
#    case. A new CGI::Session object is created and assigned to $s, say C, which
#    shares the driver B (see log below).
#
#    - When the end of program is reached (line 5 above), C is caught to be 
#    flushed by DESTROY. B having already disappeared out the scene, a
#    new driver is specially created at this time of death only to allow the 
#    flushing (DESTROY >> flush() >> CGI::Session::_driver).
#    This new driver ignores $opt_dsn (for instance Directory => /my/temp), 
#    so the flushing creates or updates session files
#    at the wrong place...
#
#    And it appears that
#    C->{_DRIVER_ARGS} is also gone,
#
#    -----------------------------------------------------
#    My analysis of the problem
#
#    Statement line 3 leads CGI::Session::Driver::new() to physically alter 
#    its argument (here $opt_dsn) by turning it into a driver object (bless 
#    $opt_dsn, <driver>).
#
#    So $opt_dsn data is no longer a private custom data structure : it has 
#    turned into an object (B) elligible for a premature DESTROY
#    when it goes out of reach after statement 4 resets $s.
#
#    As such, and unfortunate as it is, the garbage collection of B is also 
#    that of $opt_dsn, and that of $s->{_DRIVER_ARGS},
#    which proves to be unavailable (long gone) when used by 
#    CGI::Session::_driver() to create a driver for the late flushing 
#    (<driverClass>->new( $self->{_DRIVER_ARGS} ).
#
#    -------------------
#    My suggestion
#
#    My idea is that the custom data, here $opt_dsn, *should not* be altered 
#    by the underlying CGI::Session logic.
#    My suggestion to restore a good behavior is to prevent 
#    CGI::Session::Driver to turn its argument into an object.
#    This is easily done by patching CGI::Forge::Driver::new() as follows
#    ( *bold* shows the suggested patch, /*bold italic*/ shows my other 
#    "perturbations" ) :
#
#    sub new {
#    /*my ($class, $args) = @_;
#    croak "Invalid argument type passed to driver: " . Dumper($args) if 
#    $args && ! ref $args;
#    $args ||= {};*/
#
#    # my $self = bless ($args, $class) # wrong : $args is a custom 
#    data that shouldn't be altered
#    my $self = bless (*{%$args}*, $class); # Instead make it a 
#    shallow-clone, and only alter the clone !
#    return $self if $self->init();
#    return $self->set_error( "%s->init() returned false", $class);
#    }
#
#    I've applied it to my CGI::Session version and the suspicious behavior 
#    was removed.
#
#    Cheers, and good luck.
#
#    I hope that CGI::Session stays around up & running : it's a fine suite 
#    of module. Thanks for contributing it.
#
#
#    Franck PORCHER
#
#    ======================= LOGS==========================
#    /*Statement line 3 ...
#    */Oct 7 16:32:21 perl logger: [CGISESSION::LOAD::1] SESSION: 
#    CGI::Session=HASH(0x87808ac)
#    Oct 7 16:32:21 perl logger: [CGISESSION::_driver] SESSION: 
#    CGI::Session=HASH(0x87808ac) DRIVER: *DRIVERARGS: _HASH(0x87b3a20)_*
#    Oct 7 16:32:21 perl logger: [DRIVER::INIT] DRIVER:* 
#    CGI::Session::Driver::file=_HASH(0x87b3a20)_* DIRECTORY: .
#    Oct 7 16:32:21 perl logger: [CGISESSION::LOAD::2] SESSION: 
#    CGI::Session=HASH(0x87808ac) DRIVER: 
#    CGI::Session::Driver::file=HASH(0x87b3a20)
#
#    ==> The 3 lines above show how $opt_dsn (*_HASH(0x87b3a20)_*) is turned 
#    into an object (_*CGI::Session::Driver::file=HASH(0x87b3a20)*_)
#
#
#    /*Statement lien 4 (rest of $s) ...*/
#    Oct 7 16:32:21 perl logger: [*CGISESSION::DESTROY*] SESSION: 
#    CGI::Session=HASH(0x87808ac) DRIVER:
#    Oct 7 16:32:21 perl logger: [*DRIVER::DESTROY*] DRIVER: 
#    _*CGI::Session::Driver::file=HASH(0x87b3a20)*_
#
#    ==> these 2 lines show that (blessed)$opt_dsn is DESTROYED prematurately..




use strict;

use File::Spec;
use Test::More ('no_plan');


BEGIN { 
    use_ok("CGI");
    use_ok('CGI::Session');
    use_ok("CGI::Session::Driver");
    use_ok("CGI::Session::Driver::file");
}

my $opt_dsn = {Directory=>File::Spec->tmpdir()};
ok(ref($opt_dsn) eq 'HASH', '$opt_dsn is HASH');

ok(my $q  = CGI->new());

ok(my $s    = CGI::Session->new("driver:file;serializer:default",  $q, $opt_dsn));

ok(ref($opt_dsn) eq 'HASH', '$opt_dsn is HASH');

# Clean up /tmp as per RT#29969.

$s -> delete();

undef($s);

ok(!defined($s), "Session object is no longer available");

ok($opt_dsn, "\$opt_dsn still exists");

is(ref($opt_dsn),'HASH', '$opt_dsn is still a hashref');

