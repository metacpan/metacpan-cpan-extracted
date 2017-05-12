
import org.keyczar.*;

public class TestDecrypt {
    public static void main(String[] args) {
        KeyczarFileReader reader = new KeyczarFileReader(args[0]);
        try {
            Crypter crypter = new Crypter(reader);
            System.out.print(crypter.decrypt(args[1])+"\n");
        } catch (org.keyczar.exceptions.KeyczarException e) {
            System.out.print("ng\n");
        }
    }
}
