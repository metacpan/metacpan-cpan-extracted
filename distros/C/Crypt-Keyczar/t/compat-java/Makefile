KEYCZAR_URL= http://keyczar.googlecode.com/files/keyczar-0.70-081811-java-1.6.jar
LOG4J_URL  = http://www.apache.org/dist/logging/log4j/1.2.16/apache-log4j-1.2.16.zip
GSON_URL   = http://google-gson.googlecode.com/files/google-gson-1.7.1-release.zip

JAVA=java
JC=javac
JFLAGS=-classpath gson.jar:log4j.jar:keyczar.jar:.

CLASSES = TestEncrypt.java TestDecrypt.java TestSign.java TestVerify.java
.SUFFIXES: .java .class
.java.class:
	javac -cp keyczar.jar $<

KEYCZAR_TOOL = $(JAVA) -cp 'log4j.jar:gson.jar:keyczar.jar' org.keyczar.KeyczarTool



all: keys classes


classes: $(CLASSES:.java=.class)

keys: sign-hmac crypt-aes crypt-rsa sign-dsa sign-rsa


sign-hmac: jar
	-mkdir $@
	$(KEYCZAR_TOOL) create --location=$@ --purpose=sign 2> /dev/null
	$(KEYCZAR_TOOL) addkey --location=$@ --status=primary 2> /dev/null

crypt-aes: jar
	-mkdir $@
	$(KEYCZAR_TOOL) create --location=$@ --purpose=crypt 2> /dev/null
	$(KEYCZAR_TOOL) addkey --location=$@ --status=primary 2> /dev/null

crypt-rsa: jar
	-mkdir $@ $@-pub
	$(KEYCZAR_TOOL) create --location=$@ --purpose=crypt --asymmetric=rsa 2> /dev/null
	$(KEYCZAR_TOOL) addkey --location=$@ --status=primary 2> /dev/null
	$(KEYCZAR_TOOL) pubkey --location=$@ --destination=$@-pub 2> /dev/null

sign-dsa: jar
	-mkdir $@ $@-pub
	$(KEYCZAR_TOOL) create --location=$@ --purpose=sign --asymmetric=dsa 2> /dev/null
	$(KEYCZAR_TOOL) addkey --location=$@ --status=primary 2> /dev/null
	$(KEYCZAR_TOOL) pubkey --location=$@ --destination=$@-pub 2> /dev/null

sign-rsa: jar
	-mkdir $@ $@-pub
	$(KEYCZAR_TOOL) create --location=$@ --purpose=sign --asymmetric=rsa 2> /dev/null
	$(KEYCZAR_TOOL) addkey --location=$@ --status=primary 2> /dev/null
	$(KEYCZAR_TOOL) pubkey --location=$@ --destination=$@-pub 2> /dev/null


jar: keyczar.jar gson.jar log4j.jar

keyczar.jar:
	curl $(KEYCZAR_URL) > keyczar.jar

gson.jar:
	curl -O $(GSON_URL)
	unzip -p -C google-gson-*.zip 'google-gson-*/gson-*.jar' > gson.jar
	rm google-gson-*.zip

log4j.jar:
	curl -O $(LOG4J_URL)
	unzip -p -C apache-log4j-*.zip  'apache-log4j-*/log4j-*.jar' > log4j.jar
	rm apache-log4j-*.zip


distclean: clean clean-keys clean-jar


clean:
	$(RM) -f *.class
	$(RM) -f *.out *.out1 *.out2
	$(RM) -f *.zip

clean-jar:
	$(RM) -f *.jar

clean-keys:
	$(RM) -rf sign-hmac crypt-aes crypt-rsa crypt-rsa-pub sign-rsa sign-rsa-pub sign-dsa sign-dsa-pub
