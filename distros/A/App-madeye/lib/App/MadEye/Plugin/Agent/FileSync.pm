package App::MadEye::Plugin::Agent::FileSync;
use strict;
use warnings;
use App::MadEye::Plugin::Agent::Base;
use Net::SSH qw/ssh_cmd/;
use Params::Validate ':all';
use YAML ();
use Text::Diff qw(diff);

my $drivers = {
    svn => sub {
        my %args = validate(@_ => {
            url => 1,
        });
        `svn cat $args{url}`;
    },
    ssh => sub {
        my %args = validate(
            @_ => {
                host => 1,
                path => 1,
            },
        );
        ssh_cmd $args{host}, "cat $args{path}";
    },
};

sub is_dead {
    my ($self, $target) = @_;

    my $get = sub {
        my $x = shift;
        my $driver = $drivers->{$x->{driver}} or die "unknown driver: $x->{driver}";
        $driver->( %{ $x->{args} } );
    };

    my $src = $get->( $target->{src} );
    my $dst = $get->( $target->{dst} );
    if ($src ne $dst) {
        return diff(\$src, \$dst);
    } else {
        return; # success
    }
}

1;
__END__

=head1 NAME

App::MadEye::Plugin::Agent::FileSync - are two files same??

=head1 SYNOPSIS

    - module: Agent::FileSync
      conf:
        - src:
            driver: svn
            args:
              url: http://svn.example.com/trunk/foo/perlbal.conf
          dst:
            driver: ssh
            args:
              host: 192.168.1.3
              path: /etc/perlbal/perlbal.conf

=head1 DESCRIPTION

are two files same?

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
              - type: map
                required: yes
                mapping:
                    src:
                        type: map
                        required: yes
                        mapping:
                            driver:
                                type: str
                            args:
                                type: any
                    dst:
                        type: map
                        required: yes
                        mapping:
                            driver:
                                type: str
                            args:
                                type: any

=head1 AUTHORS

Tokuhiro Matsuno

