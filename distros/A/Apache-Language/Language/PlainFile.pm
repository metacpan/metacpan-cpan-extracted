package Apache::Language::PlainFile;

use strict;
use Apache::Language::Constants;
use vars qw($VERSION);

$VERSION = '0.03';

sub modified {
    my ($class, $data, $cfg) = @_;
    my $lastmod = (stat $cfg->{DictName})[9];
    return $lastmod > $cfg->{LastModified};
}

sub store {
    my ($class, $data, $cfg, $key, $lang, $value) = @_;
    $cfg->{DATA}{$key}{$lang} = $value;
    return L_OK;
    }

sub fetch {
    my ($class, $data, $cfg, $key, $lang) = @_;	
    return $cfg->{DATA}{$key}{$lang} if $lang;  
    
    my $variant = $data->best_lang(keys % {$cfg->{DATA}{$key}});
    return $cfg->{DATA}{$key}{$variant} if $variant;
    return undef;     
}

sub firstkey {
    my ($class, $data, $cfg) = @_;
    my $a = keys % {$cfg->{DATA}};
    return each % {$cfg->{DATA}};
    }

sub nextkey {
    my ($class, $data, $cfg, $lastkey) = @_;
    return each % {$cfg->{DATA}};
    }

    
sub initialize {
            my ($self, $data, $cfg) = @_;
            my $filename = $data->filename;
            
            if ($data->package =~ /^Apache::ROOT/)
				{
				#This is under Apache::Registry, so simply append .dic to the script name
				$filename =~ s/^(.*)$/$1.dic/;
				}
            else {
                $filename =~ s/\.[^.]*$/.dic/;		#Find the language file
                }
            $cfg->{DictName} = $filename;
            $cfg->{LastModified} = (stat $filename)[9];
            my $fh = IO::File->new;
			$fh->open($filename) or return L_DECLINED;

		local($/) = "";		#read untill empty line
		while (<$fh>){
			#this should be more carefully validating stuff..
			my ($lang, $code) = /([^:]*):(\w+)/ or last;
			unless ($code){
                warn __PACKAGE__ . ": bad syntax in $filename ($_)";
                return L_ERROR;
                }
			my $string = <$fh> if defined($fh) or "No string found";
			$cfg->{DATA}{$code}{$lang} = $string;
			}	
		$fh->close;
        return L_OK;
}
1;
__END__

=head1 NAME

Apache::Language::PlainFile - Default LanguageHandler under Apache::Language

=head1 SYNOPSIS

  Since it's the default handler, it never needs to be activated.

=head1 DESCRIPTION

This is the default LanguageHandler under Apache::Language.  It searches language
definitions for a specific script/module in a file with a corresponding name.  For
a script, it's the scriptname with a .dic added.  For a module, simply replace the
.pm with a .dic
  
That file must reside in the same directory as the script/module it describes, and
be readable by the web-server process.  The format of that file is as follows:
  
 language-tag:Key
 
 Content for 'language' version of 'Key'
 
 language-tag:Key
 
 [...]
 
 
The only really important thing is to make sure that entries are separated with
completely blank lines.

=head1 TODO

Nothing for now.

=head1 SEE ALSO

perl(1), L<Apache>(3), L<Apache::Language>(3) L<Apache::Language::Constants>(3), and all L<Apache::Language::*>. 

=head1 SUPPORT

Please send any questions or comments to the Apache modperl 
mailing list <modperl@apache.org> or to me at <gozer@ectoplasm.dyndns.com>

=head1 NOTES

This code was made possible by :

=over

=item *

Doug MacEachern <dougm@pobox.com>  Creator of mod_perl.  That should mean enough.

=item *

Andreas Koenig <koenig@kulturbox.de> The one I got the idea from in the first place.

=item *

The mod_perl mailing-list at <modperl@apache.org> for all your mod_perl related problems.

=back

=head1 AUTHOR

Philippe M. Chiasson <gozer@ectoplasm.dyndns.com>

=head1 COPYRIGHT

Copyright (c) 1999 Philippe M. Chiasson. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
