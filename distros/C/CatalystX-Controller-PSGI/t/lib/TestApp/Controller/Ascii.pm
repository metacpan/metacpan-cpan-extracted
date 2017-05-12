package TestApp::Controller::Ascii;
use Moose;
use namespace::autoclean;

BEGIN { extends 'CatalystX::Controller::PSGI'; }

use Plack::Response;

has 'lolcopter' => (
    is      => 'ro',
    builder => '_build_lolcopter',
);
sub _build_lolcopter{
    return <<END;
ROFL:ROFL:ROFL:ROFL
         _^___
 L    __/   [] \
LOL===__        \
 L      \________]
         I   I
        --------/
END
}

has 'hypnotoad' => (
    is      => 'ro',
    builder => '_build_hypnotoad',
);
sub _build_hypnotoad {
    return <<END;
               ,'``.._   ,'``.
              :,--._:)\,:,._,.:       All Glory to
              :`--,''   :`...';\      the HYPNO TOAD!
               `,'       `---'  `.
               /                 :
              /                   \
            ,'                     :\.___,-.
           `...,---'``````-..._    |:       \
             (                 )   ;:    )   \  _,-.
              `.              (   //          `'    \
               :               `.//  )      )     , ;
             ,-|`.            _,'/       )    ) ,' ,'
            (  :`.`-..____..=:.-':     .     _,' ,'
             `,'\ ``--....-)='    `._,  \  ,') _ '``._
          _.-/ _ `.       (_)      /     )' ; / \ \`-.'
         `--(   `-:`.     `' ___..'  _,-'   |/   `.)
             `-. `.`.``-----``--,  .'
               |/`.\`'        ,','); SSt
                   `         (/  (/
END
}

my $lolcopter_app = sub {
    my ( $self, $env ) = @_;

    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->body( $self->lolcopter );

    return $res->finalize;
};

my $notcopter_app = sub {
    my ( $self, $env ) = @_;

    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->body( "totally not a lolcopter" );

    return $res->finalize;
};

my $hypnotoad_app = sub {
    my ( $self, $env ) = @_;

    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->body( $self->hypnotoad );

    return $res->finalize;
};

__PACKAGE__->mount( '/lol/copter' => $lolcopter_app );
__PACKAGE__->mount( '/not/copter' => $notcopter_app );
__PACKAGE__->mount( '/hypnotoad' => $hypnotoad_app );

sub index: Private {
    my ( $self, $c ) = @_;

    $c->res->body('sub index: Private content');
}

sub other: Path('other') Args(0) {
    my ( $self, $c ) = @_;

    $c->res->body('normal controller methods work as well!');
}

__PACKAGE__->meta->make_immutable;
