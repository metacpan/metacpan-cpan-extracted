#!/usr/bin/env perl
use feature qw(say);
use strict;
use utf8;
use warnings qw(all);

use YADA;

YADA->new->append(
    [qw[
        http://www.cpan.org/modules/by-category/02_Language_Extensions/
        http://www.cpan.org/modules/by-category/02_Perl_Core_Modules/
        http://www.cpan.org/modules/by-category/03_Development_Support/
        http://www.cpan.org/modules/by-category/04_Operating_System_Interfaces/
        http://www.cpan.org/modules/by-category/05_Networking_Devices_IPC/
        http://www.cpan.org/modules/by-category/06_Data_Type_Utilities/
        http://www.cpan.org/modules/by-category/07_Database_Interfaces/
        http://www.cpan.org/modules/by-category/08_User_Interfaces/
        http://www.cpan.org/modules/by-category/09_Language_Interfaces/
        http://www.cpan.org/modules/by-category/10_File_Names_Systems_Locking/
        http://www.cpan.org/modules/by-category/11_String_Lang_Text_Proc/
        http://www.cpan.org/modules/by-category/12_Opt_Arg_Param_Proc/
        http://www.cpan.org/modules/by-category/13_Internationalization_Locale/
        http://www.cpan.org/modules/by-category/14_Security_and_Encryption/
        http://www.cpan.org/modules/by-category/15_World_Wide_Web_HTML_HTTP_CGI/
        http://www.cpan.org/modules/by-category/16_Server_and_Daemon_Utilities/
        http://www.cpan.org/modules/by-category/17_Archiving_and_Compression/
        http://www.cpan.org/modules/by-category/18_Images_Pixmaps_Bitmaps/
        http://www.cpan.org/modules/by-category/19_Mail_and_Usenet_News/
        http://www.cpan.org/modules/by-category/20_Control_Flow_Utilities/
        http://www.cpan.org/modules/by-category/21_File_Handle_Input_Output/
        http://www.cpan.org/modules/by-category/22_Microsoft_Windows_Modules/
        http://www.cpan.org/modules/by-category/23_Miscellaneous_Modules/
        http://www.cpan.org/modules/by-category/24_Commercial_Software_Interfaces/
        http://www.cpan.org/modules/by-category/25_Bundles/
        http://www.cpan.org/modules/by-category/26_Documentation/
        http://www.cpan.org/modules/by-category/27_Pragma/
        http://www.cpan.org/modules/by-category/28_Perl6/
        http://www.cpan.org/modules/by-category/99_Not_In_Modulelist/
    ]] => sub {
        say $_[0]->final_url;
        say ${$_[0]->header};
    },
)->wait;
