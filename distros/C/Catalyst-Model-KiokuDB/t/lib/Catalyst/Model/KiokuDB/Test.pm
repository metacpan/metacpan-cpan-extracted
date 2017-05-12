package # hide from PAUSE
Catalyst::Model::KiokuDB::Test;

use Catalyst qw(
    -Debug
    Authentication
);

{
    package # hide from PAUSE
    FakeLogger;

    sub clear { @{$_[0]} = () }

    sub str { join "\n", map { "$_->[0] - $_->[1]" } @{$_[0]} }

    sub AUTOLOAD {
        my $self = shift;
        my ( $method ) = ( our $AUTOLOAD =~ /(\w+)$/ );
        push @$self, [ $method => @_ ];
    }
}

our $log = bless [], "FakeLogger";

__PACKAGE__->log($log);

__PACKAGE__->config(
	'Plugin::Authentication' => {
		realms => {
			default => {
				credential => {
					class         => 'Password',
					password_type => 'self_check'
				},
				store => {
					class      => 'Model::KiokuDB',
                    model_name => "kiokudb",
				}
			}
		}
	}
);

__PACKAGE__->setup();

__PACKAGE__

__END__
