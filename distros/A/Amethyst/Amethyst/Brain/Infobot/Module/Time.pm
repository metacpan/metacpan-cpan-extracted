package Amethyst::Brain::Infobot::Module::Time;

use strict;
use vars qw(@ISA $ZONEDIR);
use Date::Format;
use Text::Soundex;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);
$ZONEDIR = "/usr/share/zoneinfo/";

sub new {
	my $class = shift;

	my $self  = $class->SUPER::new(
					Name		=> 'Time',
					# Regex		=> qr/^(what is the? )?time/i,
					Usage		=> '(what is the )? time in <zone>',
					Description	=> "Print the time in a particular " .
									"place.",
					@_
						);

	$ZONEDIR = $self->{Zonedir} if exists $self->{Zonedir};

	my @zones = split("\n", qx{find $ZONEDIR -type f});
	@zones = map { s/^$ZONEDIR//go; $_ } @zones;
	@zones = grep { $_ !~ /^(posix|right|SystemV|Etc)/ } @zones;
	@zones = grep { $_ !~ /\.tab$/ } @zones;

	my %zones = ();

	foreach (@zones) {
		my $x = lc $_;
		$zones{$x} = $_;
		$x =~ s,.*/,,;
		$zones{$x} = $_ unless exists $zones{$x};
	}

	# Special cases... *cough*
	$zones{bath} = $zones{london};

	$self->{Zonemap} = \%zones;

	return bless $self, $class;
}

sub process {
    my ($self, $message) = @_;

	my $content = lc $message->content;
	$content =~ s/\s+/ /g;

	unless (($content =~ /^what is the time/) ||
		($content =~ /^what time is it/) ||
		($content =~ /^time in /)) {
		return undef;
	}

	my $zone = undef;

	if ($content =~ / in (.*)/) {
		my $zonename = lc $1;
		$zonename =~ s/ /_/g;
		$zonename =~ s/[?\.\s]*$//;

		$zone = $self->{Zonemap}->{$zonename};
		unless ($zone) {
			my $sdx = soundex($zonename);
			my @zones = grep { soundex($_) eq $sdx }
							keys %{$self->{Zonemap}};

			unless (@zones) {
				my $init = substr($zonename, 0, 2);
				@zones = grep { /^$init/ } keys %{$self->{Zonemap}};
			}

			my $msg = "I have not heard of $zonename.";
			if (@zones == 0) {
				my $reply = $self->reply_to($message, $msg);
				$reply->send;
				return 1;
			}
			elsif (@zones == 1) {
				$msg .= " I think you mean " . $zones[0] . ".";
				my $reply = $self->reply_to($message, $msg);
				$reply->send;
				$zone = $self->{Zonemap}->{$zones[0]};
			}
			else {
				@zones = grep { $_ !~ m,/, } @zones if @zones > 10;

				$msg .= " Perhaps you mean one of " . join(", ", @zones)
								if @zones;
				my $reply = $self->reply_to($message, $msg);
				$reply->send;
				return 1;
			}
		}
	}

	local $ENV{TZ} = $zone;
	my $date = ctime(time);
	chomp($date);
	$date .= " ($zone)" if $zone;
	my $reply = $self->reply_to($message, $date);
	$reply->send;

	return 1;
}

1;
