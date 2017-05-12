#!/bin/bash

chromium-browser -incognito --disable-web-security http://localhost:3000/app/launch.html &
sleep 3
wmctrl -r "AV Status" -b add,above
