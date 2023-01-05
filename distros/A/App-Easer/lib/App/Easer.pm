package App::Easer;
use v5.24;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '2.006' }

sub import ($package, @args) {
   my $api = 'V1'; # default
   $api = uc(shift @args) if @args && $args[0] =~ m{\A V\d+ \z}imxs;
   require "App/Easer/$api.pm";
   "App::Easer::$api"->export_to_level(1, $package, @args);
}

1;

__END__
