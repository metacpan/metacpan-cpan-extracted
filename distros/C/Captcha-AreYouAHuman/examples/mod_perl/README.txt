This is a mod_perl example; configure it in your Apache configuration
file with something like:


        PerlSetVar HTMLTemplate /var/www/perl/template.html

        <Location /ayahdemo>
                SetHandler perl-script
                PerlResponseHandler     AYAHDemoHandler
        </Location>

(You may have to make a PerlRequire file to modify @INC to 
find AYAHDemoHandler; it's not included in the installation but
just the mod_perl example.)

The demo shows a simple form with the PlayThru embedded.  When
you submit it, it submits to itself, and will be scored.  If 
you pass, it outputs a message and a hidden conversion iframe.
If you fail, you just get the fail message and can try again.

