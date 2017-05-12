
JAVA_HOME=/opt/java1.4

CLASS=TZ
DIR=../lib/DateTime/TimeZone/HPUX
TARGET=$(DIR)/$(CLASS).class

all: $(TARGET) AllTZ.class

$(TARGET): $(CLASS).class
	mkdir -p "$(DIR)"
	cp -p $(CLASS).class "$(TARGET)"

clean:
	rm "$(TARGET)" $(CLASS).class


.SUFFIXES: .class .java

.java.class:
	$(JAVA_HOME)/bin/javac -target 1.3 $<
