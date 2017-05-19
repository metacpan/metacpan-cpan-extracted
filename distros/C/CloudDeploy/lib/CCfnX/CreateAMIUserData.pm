package CCfnX::CreateAMIUserData {
  use Moose;
  extends 'CCfnX::UserData';
  use autodie;

  has '+text' => (lazy => 1,
                  default => sub { 
                                my $self = shift;
                                die "No files defined for generating UserData" unless defined $self->files;
                                return [ map { $self->file_to_lines($_) } @{ $self->files } ]
                             });
  has files => (is => 'ro', required => 1, isa => 'ArrayRef[Str]');
  has signal => (is => 'ro', isa => 'Bool', default => 1);
  has os_family => (is => 'ro', isa => 'Str', default => 'linux');

  sub file_to_lines {
    my ($self, $file) = @_;

    open my $fh, '<', $file;
    my @lines = ();
    while (my $line = <$fh>) {
      push @lines, $self->parse_line($line);
    }
    close $fh;

    return @lines;
  }

  around get_lines => sub {
    my ($orig, $self) = @_;
    my $lines = [ @{ $self->text } ];

    if ($self->os_family eq 'linux') {
      if ($self->signal) {
        push @$lines, $self->parse_line(qq|cfn-signal -e 0 -r "cfn-int setup complete" '#-#WaitHandle#-#'\n|);
      }
    }
    else{
      unshift @$lines, "<powershell>\n";

      if ($self->signal) {
        push @$lines, { "Fn::Join" => [ " ", [ "& cfn-signal.exe -e 0", { "Fn::Base64" => { "Ref" => "WaitHandle" } } ] ] };
      }

      push @$lines, "\n</powershell>";
    }

    return $lines;
  };
}

1;
