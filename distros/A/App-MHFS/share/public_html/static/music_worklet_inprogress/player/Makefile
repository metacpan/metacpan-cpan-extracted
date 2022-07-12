# we need a concatenated version for browsers that don't support module loading in worklets
TARGET:=worklet_processor_ff.js

$(TARGET): AudioWriterReader.js worklet_processor.js
	head -n -2 AudioWriterReader.js > $@
	tail -n +2 worklet_processor.js >> $@

clean:
	rm -f $(TARGET)

.PHONY: clean