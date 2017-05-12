
import org.keyczar.*;

public class TestVerify {
    public static void main(String[] args) {
        KeyczarFileReader reader = new KeyczarFileReader(args[0]);
        try {
            Verifier verify= new Verifier(reader);
            System.out.print(verify.verify(args[1], args[2]) ? "ok\n" : "ng\n");
            
        } catch (org.keyczar.exceptions.KeyczarException e) {
            System.out.print("ng\n");
        }

    }
}
