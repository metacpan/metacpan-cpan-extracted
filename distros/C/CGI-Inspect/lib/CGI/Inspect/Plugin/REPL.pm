package CGI::Inspect::Plugin::REPL;

use strict;
use base 'CGI::Inspect::Plugin';
use Devel::StackTrace::WithLexicals;
use Data::Dumper;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{trace} = Devel::StackTrace::WithLexicals->new;
  return $self;
}

sub process {
  my $self = shift;
  my $cmd = $self->param('cmd');
  my $output = $self->{output} || '';
  
  my $trace = $self->{trace};
  $trace->reset_pointer;
  my $frame;
  while($frame = $trace->next_frame) {
    last if $frame->package() !~ /^(Continuity|Coro|CGI::Inspect)/;
  }
  use Data::Dumper;
  
  my $package = $frame->package;

  my $declarations = join "\n",
                     map {"my $_;"}
                     keys %{ $frame->lexicals || {} };

  my $aliases = q|
    while (my ($k, $v) = each %{ $frame->lexicals }) {
      Devel::LexAlias::lexalias 0, $k, $v;
    }
  |;

  my $code = qq|
    package $package;
    use Devel::LexAlias;
    no warnings 'misc'; # declaration in same scope masks earlier instance
    no strict 'vars';   # so we get all the global variables in our package
    $declarations
    sub __execute_cmd {
      $aliases
      return $cmd
    }
    return __execute_cmd();
  |;

  if($cmd) {
      local $Data::Dumper::Terse = 1;
      my $new_output = "\n> " . $cmd . "\n";
      $new_output .= Dumper(eval($code));
      $new_output .= "Error: $@\n" if $@;
      $new_output =~ s{<}{\&lt;}g;
      $output .= $new_output;
  }
  $self->{output} = $output;

  $output = qq{
    <div class=dialog id=repl title='Read-Eval-Print'>
      <pre>
        $output
      </pre>
      &gt; <input type=text name=cmd id=cmd size=40>
      <input type=submit name=send value="Send"></pre>
      <script>document.getElementById('cmd').focus()</script>
    </div>
  };

  return $output;
}

1;

