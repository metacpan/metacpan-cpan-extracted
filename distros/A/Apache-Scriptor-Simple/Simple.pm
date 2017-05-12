package Apache::Scriptor::Simple;
$VERSION="1.21";
use Apache::Scriptor;

# Директория обработчиков по умолчанию
my $DefHandDir="handlers";

#############################################################################
# Первым делом проверяем, не запускается ли случаем этот скрипт 
# нелегальным образом и, если это так, перебрасываем в корень.
# Запуск не как CGI?
if(!$ENV{DOCUMENT_ROOT} || !$ENV{SCRIPT_NAME} || !$ENV{SERVER_NAME}) {
  print "This script has to be used only as Apache handler!\n\n";
  exit;
}
# Запуск "напрямую"?
if(!$ENV{REDIRECT_URL}) {
  print "Location: http://$ENV{SERVER_NAME}/\n\n";
  exit;
}
#############################################################################

sub import 
{ my ($pkg,$HandDir);
  # По умолчанию?
  if(!defined $HandDir) {
    use FindBin qw($Bin);
    ($Bin) = $Bin=~/(.*)/;
    $HandDir = "$Bin/$DefHandDir";
  }
  require Apache::Scriptor;
  my $Scr=Apache::Scriptor->new();
  # Устанавливаем директорию с обработчиками.
  $Scr->set_handlers_dir($HandDir);
  # Поехали.
  my ($uri)  = $ENV{REQUEST_URI}=~/(.*)/;
  my ($path) = $ENV{PATH_TRANSLATED}=~/(.*)/;
  $Scr->run_uri($uri, $path);
}

return 1;
__END__


=head1 NAME

Apache::Scriptor::Simple - The simplest way to activate Apache::Scriptor.

=head1 SYNOPSIS

  #!/usr/local/bin/perl -w 
  # Use "handlers" handler directory:
  use Apache::Scriptor::Simple; 
  # that's all!

  #!/usr/local/bin/perl -w 
  # Custom handler directory:
  use Apache::Scriptor::Simple("myhandlers"); 
  # that's all!

=head1 DESCRIPTION

This module is used to make the work of creation Apache handler schipt easily. See 
example in Apache::Scriptor module.

=head1 EXAMPLE

  ### File /.htaccess:
    # Setting up the conveyor for .htm:
    # "input" => eperl => s_copyright => "output" 
    Action     perl "/_Kernel/Scriptor.pl"
    AddHandler perl .htm
    Action     s_copyright "/_Kernel/Scriptor.pl"
    AddHandler s_copyright .htm

  ### File /_Kernel/Scriptor.pl:
    #!/usr/local/bin/perl -w 
  use Apache::Scriptor::Simple; 

  ### File /test.htm:
    print "<html><body>Hello, world!</body></html>";

  ### File /_Kernel/handlers/s_copyright.pl:
    sub s_copyright
    {  my ($input)=@_;
       -f $ENV{SCRIPT_FILENAME} or return -1; # Error indicator
       # Adds the comment string BEFORE all the output.
       print '<!-- Copyright (C) by Dmitry Koterov (koterov at cpan dot org) -->\n'.$input;
       return 0; # OK
    }

  ### Then, user enters the URL: http://ourhost.com/test.htm.
  ### The result will be:
    Content-type: text/html\n\n
    <!-- Copyright (C) by Dmitry Koterov (koterov at cpan dot org) -->\n
    Hello, world!

=head1 AUTHOR

Dmitry Koterov <koterov at cpan dot org>, http://www.dklab.ru

=head1 SEE ALSO

C<Apache::Scriptor>.

=cut
