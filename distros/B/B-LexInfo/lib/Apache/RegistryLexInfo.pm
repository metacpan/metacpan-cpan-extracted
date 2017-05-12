package Apache::RegistryLexInfo;

use strict;
use Apache::RegistryNG ();
use B::LexInfo ();

{
    no strict;
    @ISA = qw(Apache::RegistryNG);
}

sub is_html { shift->content_type eq "text/html" }

#RegistryNG uses filename, might be loooong
sub namespace_from { shift->uri }

sub run {
    my $pr = shift;
    my $package = $pr->namespace;

    my $lexi = B::LexInfo->new;
    my $before = $lexi->stash_cvlexinfo($package);
    $pr->SUPER::run(@_);
    my $after = $lexi->stash_cvlexinfo($package);
    my $diff = $lexi->diff($before, $after);

    my $is_html = $pr->is_html;
    my $hr = $is_html ? "<hr>" : "-=" x 50;
    my $nl = $is_html ? "<br>\n" : "\n";
    print "<pre>\n" if $is_html;
    print "$hr\n";
    print "Diff:$nl", $$diff, "$hr\n";
    print "Before:$nl", ${ $lexi->dumper($before) }, "$hr\n";
    print "After:$nl", ${ $lexi->dumper($after) }, "$hr\n";
}

1;
__END__

=head1 NAME

Apache::RegistryLexInfo - Diff Apache::Registry script padlists

=head1 SYNOPSIS

 Alias /lexinfo /same/path/as/for/apache/registry/scripts

 PerlModule Apache::RegistryLexInfo
 <Location /lexinfo>
  SetHandler perl-script
  PerlHandler Apache::RegistryLexInfo->handler
  Options +ExecCGI 
 </Location>

=head1 DESCRIPTION

I<Apache::RegistryLexInfo> is a subclass of I<Apache::RegistryNG>
which takes snapshots of the handler padlist before and after it is
run.  The differences (if any) and the before/after snapshots are
printed to the HTTP stream after the script has run.

=head1 SEE ALSO

The Apache::Status I<StatusLexInfo> option.

Apache::RegistryNG(3), B::LexInfo(3)

=head1 AUTHOR

Doug MacEachern
