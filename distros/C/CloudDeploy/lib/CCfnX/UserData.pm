package CCfnX::UserData {
  use Moose;
  use Cfn;

  extends 'Cfn::Value';

  has '+Value' => (required => 0);
  has text => (is => 'ro', required => 1, isa => 'Str|ArrayRef');

  sub parse_line {
    my ($self, $line) = @_;
    return $line if (ref($line));
    # Use a capturing group in split so that #-#...#-# is returned
    my @elements = split /(\#\-\#.*?\#\-\#)/, $line;
    @elements = map {
      ($_ =~ m/^#\-\#(.*?)\#\-\#$/) ?
        _process_tiefighter("$1") : $_
    } @elements;
    return @elements;
  }

  use CCfnX::Shortcuts;
  sub _process_tiefighter {
    my ($tfighter) = @_;
    if ($tfighter =~ m/^([A-Za-z0-9:-]+?)\-\>([A-Za-z0-9.:-]+?)$/) {
      return { 'Fn::GetAtt' => [ "$1", "$2" ] };
    } elsif ($tfighter =~ m/^Parameter\(['"]{0,1}([A-Za-z0-9:_-]+?)['"]{0,1}\)$/) {
      my $param = "$1";
      return CCfnX::Shortcuts::Parameter($param);
    } elsif ($tfighter =~ m/^Attribute\(([A-Za-z0-9.:_-]+?)\)$/) {
      my $path = "$1";
      return CCfnX::Shortcuts::Attribute($path);
    } elsif ($tfighter =~ m/^([A-Za-z0-9:-]+)$/) {
      return { Ref => "$1" }
    } else {
      die "Unrecognized tiefighter syntax for $tfighter";
    }
  }

  sub get_lines {
    my $self = shift;
    if (defined $self->text) {
      if (ref($self->text) eq 'ARRAY'){
        return [ map { $self->parse_line($_) } @{ $self->text } ];
      } else {
        return [ $self->parse_line($self->text) ];
      }
    } else {
      die "No text for generating UserData";
    }
  }

  sub process_with_context {
    my ($self, $ctx) = @_;
    return [ map {
        (not ref($_) or ref($_) eq 'HASH')?$_:$_->as_hashref($ctx);
      } @{ $self->get_lines } ]
  }

  sub as_hashref_joins {
    my $self = shift;
    return {
      'Fn::Join' => [ '', $self->process_with_context(@_) ]
    }
  }

  around as_hashref => sub {
    my ($orig, $self, @rest) = @_;
    return {
      'Fn::Base64' => $self->as_hashref_joins(@rest)
    }
  };
}

1;
