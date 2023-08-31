#!/bin/bash

# This sample program was provided as-is and it may or may not work for you.

# This sample launcher assumes that
# i) You have docker installed
# ii) You don't have access to a Hadoop installation and want to have one for testing.
#

# This is a sample wrapper, you don't need to use this.
# See https://hub.docker.com/r/cloudera/quickstart/
# For the actual source on how to launch the cloudera
# image.
#
# Note that the image will have the whole cloudera ecosystem
# and it would be relatively a heavy image.
#
# It is also possible for you to build your own image and not depend on this.
# However, that's up to you.
#

IMAGE_NAME="cloudera/quickstart"

echo -e "\033[31m[INFO]\033[0m Hello, there. Please \`cat $0\` to see additional comments about this program..."
echo -e "\033[31m[INFO]\033[0m Pulling the cloudera image, including all the bells and whistles ..."

docker pull $IMAGE_NAME":latest"

echo -e "\033[31m[INFO]\033[0m Executing the image. It will take a while for everything to actually boot-up on an old machine ..."
echo -e "\033[31m[INFO]\033[0m docker will also take some time to setup all the port forwarding ..."
echo -e "\033[31m[INFO]\033[0m ... do not be surprised if the services are not up yet after you have the shell..."

# port setup is here so that you can access the inside services as
# localhost:PORT from your own host device (laptop, over local network, etc)
#
# Note that these are the ports set inside the image and we don't control
# any of those from here and just making them accessible with port forwarding.
#

HTTPFS_ADMIN_PORT=14001
HTTPFS_HTTP_PORT=14000
OOZIE_ADMIN_PORT=11001
OOZIE_HTTPS_PORT=11443
OOZIE_HTTP_PORT=11000
SQOOP_ADMIN_PORT=12001
SQOOP_HTTP_PORT=12000

docker run  --hostname=quickstart.cloudera             \
            --privileged=true                          \
            -p "$HTTPFS_ADMIN_PORT:$HTTPFS_ADMIN_PORT" \
            -p "$HTTPFS_HTTP_PORT:$HTTPFS_HTTP_PORT"   \
            -p "$OOZIE_ADMIN_PORT:$OOZIE_ADMIN_PORT"   \
            -p "$OOZIE_HTTPS_PORT:$OOZIE_HTTPS_PORT"   \
            -p "$OOZIE_HTTP_PORT:$OOZIE_HTTP_PORT"     \
            -p "$SQOOP_ADMIN_PORT:$SQOOP_ADMIN_PORT"   \
            -p "$SQOOP_HTTP_PORT:$SQOOP_HTTP_PORT"     \
            -it "$IMAGE_NAME"                          \
            "/usr/bin/docker-quickstart"

echo -e "\033[31m[INFO]\033[0m Goodbye!"

