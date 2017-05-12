CREATE OR REPLACE FUNCTION employee_save () RETURNS TRIGGER AS $$
BEGIN
	NEW.login := regexp_replace(lower(NEW.login),'[^a-z]','','g');
	IF TG_OP = 'UPDATE' THEN
		IF NEW.passwd != OLD.passwd THEN
			NEW.passwd := md5(NEW.login || NEW.passwd);
		END IF;
	ELSE
		NEW.passwd := md5(NEW.login || NEW.passwd);
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER employee_save BEFORE UPDATE OR INSERT
ON employees FOR EACH ROW EXECUTE PROCEDURE employee_save();
