GET {
  TIMERANGE { [% DATE_FROM %] [% DATE_TO %] }
  READERS {
    ea:pageview@[% SITE %] AS pageview
    ea:clickview@[% SITE %] AS clickview
  }
  GROUPS {
    session WITH pageview IF {
      session.last.pageview.timestamp + MINS( 30 ) <= pageview.timestamp
    }
  }
  JOINS {
    session WITH clickview IF {
      session.last.pageview.timestamp == clickview.timestamp
    } AS visitwchannel
  }
  OUTPUTS_ROW( visitwchannel ) {
    visitwchannel.session.first.pageview.uid,
    visitwchannel.session.first.pageview.timestamp,
    visitwchannel.session.last.pageview.timestamp,
    visitwchannel.session.first.pageview.userinfo.idcustomer,
    visitwchannel.session.last.pageview.userinfo.idcustomer,
    visitwchannel.session.first.pageview.device.deviceplatform.version,
    visitwchannel.session.first.pageview.device.deviceplatform.deviceplatformvendorname.deviceplatformvendor.vendor,
    visitwchannel.session.first.pageview.device.deviceplatform.deviceplatformvendorname.name,
    visitwchannel.session.first.pageview.device.devicebrowser.version,
    visitwchannel.session.first.pageview.device.devicebrowser.devicebrowservendorname.name,
    visitwchannel.session.first.pageview.device.devicebrowser.devicebrowservendorname.devicebrowservendor.vendor,
    visitwchannel.session.first.pageview.device.devicehardware.name,
    visitwchannel.session.first.pageview.device.devicehardware.devicehardwarevendor.vendor,
    visitwchannel.session.first.pageview.device.devicescreeninches,
    visitwchannel.session.first.pageview.device.devicetype.type
  }
  LIMIT 100
};
