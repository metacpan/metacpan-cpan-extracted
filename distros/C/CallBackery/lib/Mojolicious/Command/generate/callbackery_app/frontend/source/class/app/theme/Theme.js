% my $p = shift;
/* ************************************************************************
   Copyright: <%= $p->{year} %> <%= $p->{fullName} %>
   License:   ???
   Authors:   <%= $p->{fullName} %> <<%= $p->{email} %>>
 *********************************************************************** */
qx.Theme.define("<%= $p->{qxclass} %>.theme.Theme", {
    meta : {
        color : callbackery.theme.Color,
        decoration : callbackery.theme.Decoration,
        font : callbackery.theme.Font,
        icon : qx.theme.icon.Tango,
        appearance : callbackery.theme.Appearance
    }
});
