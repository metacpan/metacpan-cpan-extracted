<div class="navbar navbar-inverse navbar-fixed-top">
   <div class="navbar-inner">
      <div class="container">
          <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="brand" href="#">App::Standby</a>
          <div class="nav-collapse collapse">
            <ul class="nav">
            [% FOREACH line IN groups %]
              <li class="dropdown[% IF line.id == group_id %] active[% END %]">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown">[% line.name %] <b class="caret"></b></a>
                <ul class="dropdown-menu">
                  <li><a href="?rm=overview&group_id=[% line.id %]">Group</a></li>
                  <li><a href="?rm=list_contacts&group_id=[% line.id %]">Contacts</a></li>
                  <li><a href="?rm=list_config&group_id=[% line.id %]">Config</a></li>
                  <li><a href="?rm=list_services&group_id=[% line.id %]">Services</a></li>
                </ul>
              </li>
              [% END %]
              <li><a href="?rm=list_groups">[% "Manage Groups" | l10n %]</a></li>
            </ul>
          </div><!--/.nav-collapse -->
      </div>
    </div>
</div>

